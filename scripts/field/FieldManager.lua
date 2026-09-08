-- Local values: FieldManager_mt
FieldManager = {}
FieldManager.FIELDSTATE_PLOWED = 0
FieldManager.FIELDSTATE_CULTIVATED = 1
FieldManager.FIELDSTATE_GROWING = 2
FieldManager.FIELDSTATE_HARVESTED = 3
FieldManager.FIELDEVENT_PLOWED = 1
FieldManager.FIELDEVENT_CULTIVATED = 2
FieldManager.FIELDEVENT_HARVESTED = 3
FieldManager.FIELDEVENT_GROWN = 4
FieldManager.FIELDEVENT_WEEDED = 5
FieldManager.FIELDEVENT_SPRAYED = 6
FieldManager.FIELDEVENT_SOWN = 7
FieldManager.FIELDEVENT_WITHERED = 8
FieldManager.FIELDEVENT_GROWING = 9
FieldManager.FIELDEVENT_FERTILIZED = 10
FieldManager.FIELDEVENT_LIMED = 11
FieldManager.DEBUG_SHOW_FIELDSTATUS = false
FieldManager.DEBUG_SHOW_NPC_ACTIONS = false
FieldManager.NPC_START_TIME = 21600000
FieldManager.NPC_END_TIME = 79200000
local FieldManager_mt = Class(FieldManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
	FieldManager.xmlSchema = XMLSchema.new("fields")
	FieldManager.xmlSchemaSavegame = XMLSchema.new("fields_savegame")
end)
g_xmlManager:addInitSchemaFunction(function()
	Mission00.xmlSchema:register(XMLValueType.STRING, "map.fields#filename", "Filename of the field preplanted config")
	local v2_ = FieldManager.xmlSchema
	v2_:register(XMLValueType.STRING, "map.fields.field(?)#className")
	FieldUpdateTask.registerXMLPaths(v2_, "map.fields.field(?)")
	local v3_ = FieldManager.xmlSchemaSavegame
	v3_:register(XMLValueType.STRING, "fields.task(?)#className")
	FieldUpdateTask.registerXMLPaths(v3_, "fields.task(?)")
	Field.registerXMLPaths(v3_, "fields.field(?)")
	v3_:register(XMLValueType.INT, "fields.field(?)#id", "Id of the field", nil, true)
end)

-- Upvalues: FieldManager_mt
-- Local values: self
function FieldManager.new(customMt)
	-- upvalues: (copy) FieldManager_mt
	return AbstractManager.new(customMt or FieldManager_mt)
end

function FieldManager:initDataStructures()
	self.fields = {}
	self.farmlandIdFieldMapping = {}
	self.currentFieldPartitionIndex = nil
	self.nextCheckTime = 0
	self.nextUpdateTime = 0
	self.nextFieldCheckIndex = 0
	self.updateTasks = {}
	self.fieldNumUpdateTasks = {}
	self.pendingFieldUpdatesMapping = {}
	self.pendingFieldUpdates = {}
	self.fieldStateUpdateIndex = 0
	self.fieldsDoStateUpdate = {}
	self.debugField = nil
end

-- Local values: mission, fieldGroundSystem, _, fruitType, farmlandInfoLayer, modifier, filter, i, field, preplantedFields, filename, xmlFilename, fieldsXMLFile, _, fieldKey, _, field, cellsize, fieldState, textColor
function FieldManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FieldManager:superClass().loadMapData(self)
	local v_u_9_ = g_currentMission
	self.mission = v_u_9_
	v_u_9_:addUpdateable(self)
	local v10_ = v_u_9_.fieldGroundSystem
	self.groundTypeSown = FieldGroundType.getValueByType(FieldGroundType.SOWN)
	self.sprayTypeFertilizer = FieldSprayType.getValueByType(FieldSprayType.FERTILIZER)
	self.sprayTypeLime = FieldSprayType.getValueByType(FieldSprayType.LIME)
	self.sprayLevelMaxValue = v10_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	self.plowLevelMaxValue = Platform.gameplay.usePlowCounter and (v10_:getMaxValue(FieldDensityMap.PLOW_LEVEL) or 0) or 0
	self.limeLevelMaxValue = Platform.gameplay.useLimeCounter and v10_:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0
	self.availableFruitTypeIndices = {}
	for _, v11_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
		if v11_.useForFieldMissions and v11_.allowsSeeding then
			local v12_ = self.availableFruitTypeIndices
			local v13_ = v11_.index
			table.insert(v12_, v13_)
		end
	end
	self.fruitTypesCount = #self.availableFruitTypeIndices
	self.fieldIndexToCheck = 1
	local v14_ = g_farmlandManager:getLocalMap()
	local v_u_15_ = DensityMapModifier.new(v14_, 0, g_farmlandManager.numberOfBits, g_terrainNode)
	local v_u_16_ = DensityMapFilter.new(v_u_15_)
	for v_u_17_, v_u_18_ in ipairs(self.fields) do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_18_, (copy) self, (copy) v_u_17_, (copy) v_u_16_, (copy) v_u_15_
			local v19_ = true
			local v20_, v21_ = v_u_18_:getCenterOfFieldWorldPosition()
			local v22_ = g_farmlandManager:getFarmlandAtWorldPosition(v20_, v21_)
			if v22_ == nil then
				Logging.error("FieldManager - Failed to find farmland in center of field \'%s\' at %d %d", v_u_17_, v20_, v21_)
				v19_ = false
			else
				if self.farmlandIdFieldMapping[v22_.id] ~= nil then
					Logging.error("FieldManager - There already exists field \'%d\' on farmland \'%s\'", v_u_17_, v22_.id)
					v19_ = false
				end
				v_u_16_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v22_.id)
				v_u_15_:clearPolygonPoints()
				for _, v23_ in ipairs(v_u_18_:getPolygonPoints()) do
					local v24_, _, v25_ = getWorldTranslation(v23_)
					v_u_15_:addPolygonPointWorldCoords(v24_, v25_)
				end
				local _, v26_, _ = v_u_15_:executeGet(v_u_16_)
				if v26_ > 0 then
					for v27_ = 0, #g_farmlandManager:getFarmlands() do
						if v27_ ~= v22_.id then
							v_u_16_:setValueCompareParams(DensityValueCompareType.EQUAL, v27_)
							local _, v28_, _ = v_u_15_:executeGet(v_u_16_)
							if v28_ > 0 then
								Logging.error("FieldManager - Field \'%d\' with center on farmland \'%d\' touches farmland \'%d\' with \'%d\' pixels", v_u_17_, v22_.id, v27_, v28_)
								v19_ = false
							end
						end
					end
				end
			end
			if v19_ then
				v_u_18_:setFarmland(v22_)
				v22_:setField(v_u_18_)
				self.farmlandIdFieldMapping[v22_.id] = v_u_18_
			end
		end, string.format("FieldManager:loadMapData - Field \'%d\'", v_u_17_))
	end
	if not v_u_9_.missionInfo.isValid and (g_server ~= nil and not Profiler.IS_INITIALIZED) then
		local v_u_29_ = {}
		local v30_ = getXMLString(xmlFile, "map.fields#filename")
		if v30_ ~= nil then
			local v31_ = Utils.getFilename(v30_, baseDirectory)
			local v_u_32_ = XMLFile.load("fieldsXML", v31_, FieldManager.xmlSchema)
			if v_u_32_ ~= nil then
				for _, v_u_33_ in v_u_32_:iterator("map.fields.field") do
					g_asyncTaskManager:addSubtask(function()
						-- upvalues: (copy) v_u_32_, (copy) v_u_33_, (copy) self, (copy) v_u_29_
						local v34_ = self:getFieldById((v_u_32_:getValue(v_u_33_ .. "#fieldId")))
						if v34_ ~= nil then
							local v35_ = v_u_32_:getString(v_u_33_ .. "#className", "FieldUpdateTask")
							local v36_ = ClassUtil.getClassObject(v35_)
							if v36_ ~= nil then
								local v37_ = v36_.new()
								if v37_:loadFromXMLFile(v_u_32_, v_u_33_) then
									self:addFieldUpdateTask(v37_)
									v_u_29_[v34_] = true
								end
							end
						end
					end)
				end
				g_asyncTaskManager:addSubtask(function()
					-- upvalues: (copy) v_u_32_
					v_u_32_:delete()
				end)
			end
		end
		for _, v_u_38_ in pairs(self.fields) do
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (copy) v_u_38_, (copy) v_u_29_, (copy) self, (copy) v_u_9_
				if not v_u_38_:getHasOwner() and (v_u_38_.isMissionAllowed and v_u_29_[v_u_38_] == nil) then
					local v39_ = table.getRandomElement(self.availableFruitTypeIndices)
					if v_u_38_.grassMissionOnly then
						v39_ = FruitType.GRASS
					end
					local v40_ = g_fruitTypeManager:getFruitTypeByIndex(v39_)
					if v40_ == nil then
						return
					end
					local v41_ = v40_:getRandomInitialState(g_currentMission.missionInfo.growthMode)
					local v42_ = 0
					local v43_ = FieldGroundType.SOWN
					local v44_ = v_u_38_:getAngle()
					local v45_ = FieldSprayType.NONE
					local v46_ = math.random(0, self.sprayLevelMaxValue)
					local v47_ = math.random(0, self.plowLevelMaxValue)
					local v48_ = math.random(0, self.limeLevelMaxValue)
					local v49_
					if v41_ == nil then
						v39_ = nil
						v49_ = math.random() < 0.5 and FieldGroundType.CULTIVATED or FieldGroundType.PLOWED
						if v49_ == FieldGroundType.PLOWED then
							v47_ = self.plowLevelMaxValue
						end
						if v46_ > 0 then
							v45_ = math.random() < 0.7 and FieldSprayType.LIQUID_MANURE or FieldSprayType.MANURE
						end
						if v48_ > 0 and math.random() < 0.1 then
							v45_ = FieldSprayType.LIME
						end
					else
						if v40_.plantsWeed then
							if v41_ > 4 then
								v42_ = math.random(3, 9)
							else
								v42_ = math.random(1, 7)
							end
						end
						v49_ = v40_:getGrowthStateGroundType(v41_) or v43_
					end
					if not v_u_9_.missionInfo.plowingRequiredEnabled then
						v47_ = self.plowLevelMaxValue
					end
					local v50_ = FieldUpdateTask.new()
					v50_:setField(v_u_38_)
					v50_:setFruit(v39_, v41_)
					v50_:setWeedState(v42_)
					v50_:setStoneLevel(0)
					v50_:setGroundType(v49_)
					v50_:setGroundAngle(v44_)
					v50_:setSprayType(v45_)
					v50_:setSprayLevel(v46_)
					v50_:setLimeLevel(v48_)
					v50_:setPlowLevel(v47_)
					v50_:clearHeight()
					self:addFieldUpdateTask(v50_)
				end
			end)
		end
	end
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) v_u_9_, (copy) self
		if v_u_9_:getIsServer() and g_addCheatCommands then
			addConsoleCommand("gsFieldSetState", "Opens UI to set state for specific field(s)", "consoleCommandSetFieldState", self, "[fieldId]; [fruitName]; [growthState]")
			addConsoleCommand("gsFieldSetGround", "Opens UI to set state for specific field(s)", "consoleCommandSetFieldGround", self, "[fieldId]; [groundTypeName]; [angle]; [groundLayer]; [fertilizerState]; [plowingState]; [weedState]; [limeState]; [stubbleState]; [buyField]; [removeFoliage]")
		end
		if g_addCheatCommands then
			addConsoleCommand("gsFieldToggleStatus", "Shows field status", "consoleCommandToggleDebugFieldStatus", self)
			addConsoleCommand("gsFieldToggleNPCLogging", "Toggle field npc action logging", "consoleCommandToggleDebugFieldNPCLogging", self)
		end
	end)
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) v_u_9_, (copy) self
		if not v_u_9_:getIsServer() then
			for _, v51_ in pairs(self.fields) do
				local v52_ = FieldUpdateTask.new()
				v52_:setField(v51_)
				v52_:setGroundType(FieldGroundType.CULTIVATED)
				v52_:setGroundAngle(v51_:getAngle())
				self:addFieldUpdateTask(v52_)
			end
		end
		while true do
			local v_u_53_ = table.remove(self.updateTasks, 1)
			if v_u_53_ == nil then
				break
			end
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (copy) v_u_53_, (ref) self
				v_u_53_:start()
				while not v_u_53_:getIsFinished() do
					v_u_53_:update(1)
				end
				self:onFinishFieldUpdateTask(v_u_53_)
			end)
		end
	end)
	g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
	g_messageCenter:subscribe(MessageType.MISSION_GENERATION_START, self.onMissionGenerationStart, self)
	g_messageCenter:subscribe(MessageType.MISSION_GENERATION_END, self.onMissionGenerationEnd, self)
	self.debugBitVectorMap = DebugBitVectorMap.newSimple(5, 0.5, false, 0.1)
	local v_u_54_ = FieldState.new()
	local v_u_55_ = Color.new(1, 1, 1, 0.7)
	self.debugBitVectorMap:createWithCustomFunc(function(_, p56_, p57_, p58_, _, _, p59_)
		-- upvalues: (copy) v_u_54_, (copy) v_u_55_
		local v60_ = (p56_ + p58_) * 0.5
		local v61_ = (p57_ + p59_) * 0.5
		v_u_54_:update(v60_, v61_)
		if v_u_54_.groundType == 0 then
			return 0
		end
		v_u_54_:drawDebugAtWorldPosition(v60_, getTerrainHeightAtWorldPos(g_terrainNode, v60_, 0, v61_), v61_, 0.008, v_u_55_)
		return 1
	end)
	function self.debugBitVectorMap.getShouldBeDrawn()
		return FieldManager.DEBUG_SHOW_FIELDSTATUS
	end
	g_debugManager:addElement(self.debugBitVectorMap)
end

-- Local values: _, field
function FieldManager:unloadMapData()
	if self.mission ~= nil then
		self.mission:removeUpdateable(self)
	end
	for _, v63_ in pairs(self.fields) do
		v63_:delete()
	end
	self.fields = {}
	self.fieldsToCheck = nil
	self.fieldsToUpdate = nil
	self.fieldGroundSystem = nil
	self.mission = nil
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsFieldSetState")
	removeConsoleCommand("gsFieldSetGround")
	removeConsoleCommand("gsFieldToggleStatus")
	removeConsoleCommand("gsFieldToggleNPCLogging")
	FieldManager:superClass().unloadMapData(self)
end

function FieldManager:delete() end

-- Local values: xmlFile, _, key, fieldId, field, _, key, fieldId, field, _, key, className, class, updateTask
function FieldManager:loadFromXMLFile(xmlFilename)
	local v66_ = XMLFile.load("fields", xmlFilename, FieldManager.xmlSchemaSavegame)
	if v66_ ~= nil then
		for _, v67_ in v66_:iterator("fields.field") do
			local v68_ = v66_:getInt(v67_ .. "#id")
			if v68_ ~= nil then
				local v69_ = self:getFieldById(v68_)
				if v69_ ~= nil then
					v69_:loadFromXMLFile(v66_, v67_)
				end
			end
		end
		self.pendingFieldUpdates = {}
		self.pendingFieldUpdatesMapping = {}
		for _, v70_ in v66_:iterator("fields.pendingUpdate") do
			local v71_ = v66_:getInt(v70_ .. "#fieldId")
			if v71_ ~= nil then
				local v72_ = self:getFieldById(v71_)
				if v72_ ~= nil then
					local v73_ = self.pendingFieldUpdates
					table.insert(v73_, v72_)
					self.pendingFieldUpdatesMapping[v72_] = true
				end
			end
		end
		for _, v74_ in v66_:iterator("fields.task") do
			local v75_ = v66_:getString(v74_ .. "#className", "FieldUpdateTask")
			local v76_ = ClassUtil.getClassObject(v75_)
			if v76_ ~= nil then
				local v77_ = v76_.new()
				if v77_:loadFromXMLFile(v66_, v74_) then
					self:addFieldUpdateTask(v77_)
				end
			end
		end
		v66_:delete()
	end
end

-- Local values: xmlFile, k, field, key, id, k, field, id, key, k, updateTask, needsSaving, key
function FieldManager:saveToXMLFile(xmlFilename)
	local v80_ = XMLFile.create("fields", xmlFilename, "fields", FieldManager.xmlSchemaSavegame)
	for v81_, v82_ in ipairs(self.fields) do
		local v83_ = string.format("fields.field(%d)", v81_ - 1)
		if v82_:getId() ~= nil then
			v80_:setInt(v83_ .. "#id", v82_:getId())
			v82_:saveToXMLFile(v80_, v83_)
		end
	end
	if self.pendingFieldUpdates ~= nil then
		for v84_, v85_ in ipairs(self.pendingFieldUpdates) do
			local v86_ = v85_:getId()
			if v86_ ~= nil then
				v80_:setInt(string.format("fields.pendingUpdate(%d)", v84_ - 1) .. "#fieldId", v86_)
			end
		end
	end
	for v87_, v88_ in ipairs(self.updateTasks) do
		local v89_ = v88_.needsSaving
		if v89_ or v89_ == nil then
			local v90_ = string.format("fields.task(%d)", v87_ - 1)
			v80_:setString(v90_ .. "#className", ClassUtil.getClassNameByObject(v88_))
			v88_:saveToXMLFile(v80_, v90_)
		end
	end
	v80_:save()
	v80_:delete()
end

-- Local values: pendingField
function FieldManager:update(dt)
	if g_server ~= nil then
		if self.pendingFieldUpdates == nil then
			self:setPendingFieldUpdates()
		end
		local v93_ = table.remove(self.pendingFieldUpdates, 1)
		if v93_ ~= nil then
			self.pendingFieldUpdatesMapping[v93_] = nil
			v93_:updateState()
			self:updateField(v93_)
		end
		if self.currentUpdateTask == nil then
			self.currentUpdateTask = table.remove(self.updateTasks, 1)
			if self.currentUpdateTask ~= nil then
				self.currentUpdateTask:start()
			end
		end
		if self.currentUpdateTask ~= nil then
			self.currentUpdateTask:update(dt)
			if self.currentUpdateTask:getIsFinished() then
				self:onFinishFieldUpdateTask(self.currentUpdateTask)
				self.currentUpdateTask = nil
			end
		end
	end
end

function FieldManager:addField(field)
	local v96_ = self.fields
	table.insert(v96_, field)
	self.fieldNumUpdateTasks[field] = 0
end

function FieldManager:getFieldById(fieldId)
	return self.farmlandIdFieldMapping[fieldId]
end

function FieldManager:getFields()
	return self.fields
end
function FieldManager.logNPCAction(_, p100_, ...)
	if FieldManager.DEBUG_SHOW_NPC_ACTIONS then
		Logging.devInfo(p100_, ...)
	end
end

-- Local values: fieldState, limeLevel, task, task, nextFruitTypeIndex, fruitTypeDesc, factor, factor
function FieldManager:updateField(field)
	if not field:getHasOwner() and field.isMissionAllowed then
		local v103_ = field:getFieldState()
		self:logNPCAction("FieldManager: Update field \'%s\'", field:getName())
		if v103_.fruitTypeIndex == FruitType.UNKNOWN then
			if field.plannedFruitTypeIndex == FruitType.UNKNOWN then
				field.plannedFruitTypeIndex = self:generatePlannedFruitForField(field)
				self:logNPCAction("FieldManager: Planned fruit for field \'%s\' is now \'%s\'", field:getName(), g_fruitTypeManager:getFruitTypeNameByIndex(field.plannedFruitTypeIndex))
				if v103_.limeLevel == 0 and math.random() < 0.2 then
					self:limeField(field)
					local v104_ = self:cultivateField(field)
					v104_:setSprayType(FieldSprayType.LIME)
					v104_:setLimeLevel(self.limeLevelMaxValue)
					return
				end
				if math.random() < 0.2 then
					local v105_ = self:cultivateField(field)
					local v106_
					if math.random() > 0.7 then
						v106_ = FieldSprayType.LIQUID_MANURE
					else
						v106_ = false
					end
					v105_:setSprayType(v106_, FieldSprayType.MANURE)
					v105_:setSprayLevel(1)
					return
				end
			else
				local v107_ = self:getFruitIndexForField(field)
				if v107_ ~= nil then
					self:sowField(field, v107_)
					field.plannedFruitTypeIndex = FruitType.UNKNOWN
					return
				end
			end
		else
			local v108_ = g_fruitTypeManager:getFruitTypeByIndex(v103_.fruitTypeIndex)
			if v108_:getIsCatchCrop() then
				if v108_:getIsHarvestable(v103_.growthState) then
					self:cultivateField(field)
					return
				end
			elseif v108_:getIsWithered(v103_.growthState) then
				if v108_:getIsWithered(v103_.lastGrowthState) then
					if math.random() < 0.5 then
						self:cultivateField(field)
					else
						self:plowField(field)
					end
				end
				if math.random() < 0.3 then
					self:harvestField(field)
					return
				end
			elseif v108_:getIsHarvestable(v103_.growthState) then
				if (v108_:getIsHarvestable(v103_.lastGrowthState) and 0.2 or 0.05) > math.random() then
					self:harvestField(field)
					return
				end
			elseif v108_:getIsCut(v103_.growthState) then
				if (v108_:getIsCut(v103_.lastGrowthState) and 0.4 or 0.05) > math.random() then
					if math.random() < 0.75 then
						self:cultivateField(field)
					else
						self:plowField(field)
					end
				end
			elseif v108_:getIsGrowing(v103_.growthState) then
				if v103_.sprayLevel < self.sprayLevelMaxValue and math.random() < 0.3 then
					self:fertilizeField(field)
					return
				end
				if v103_.weedState > 1 and math.random() < 0.2 then
					if v108_:getIsWeedable(v103_.growthState) then
						self:weedField(field, false)
						return
					end
					if v108_:getIsHoeable(v103_.growthState) then
						self:weedField(field, true)
						return
					end
					self:herbicideField(field)
				end
			end
		end
	end
end

-- Local values: fieldState, replacements, newWeedState, task
function FieldManager:weedField(field, isHoe)
	local v112_ = field:getFieldState()
	local v113_ = g_currentMission.weedSystem:getWeederReplacements(isHoe).weed.replacements[v112_.weedState] or 0
	local v114_ = FieldUpdateTask.new()
	v114_:setField(field)
	v114_:setWeedState(v113_)
	self:addFieldUpdateTask(v114_)
	self:logNPCAction("FieldManager: Weed field \'%s\' (Hoe: \'%s\')", field:getName(), isHoe)
	return v114_
end

-- Local values: fieldState, replacements, weedState, task
function FieldManager:herbicideField(field)
	local v117_ = field:getFieldState()
	local v118_ = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements[v117_.weedState] or 0
	local v119_ = FieldUpdateTask.new()
	v119_:setField(field)
	v119_:setWeedState(v118_)
	self:addFieldUpdateTask(v119_)
	self:logNPCAction("FieldManager: Herbicide field \'%s\'", field:getName())
	return v119_
end

-- Local values: task
function FieldManager:plowField(field)
	local v122_ = FieldUpdateTask.new()
	v122_:setField(field)
	v122_:setFruit(FruitType.UNKNOWN, 0)
	v122_:setWeedState(0)
	v122_:setStoneLevel(0)
	v122_:setGroundAngle(field:getAngle())
	v122_:setGroundType(FieldGroundType.PLOWED)
	v122_:setSprayType(FieldGroundType.NONE)
	v122_:setPlowLevel(self.plowLevelMaxValue)
	v122_:clearHeight()
	self:logNPCAction("FieldManager: Plow field \'%s\'", field:getName())
	self:addFieldUpdateTask(v122_)
	return v122_
end

-- Local values: task
function FieldManager:cultivateField(field)
	local v125_ = FieldUpdateTask.new()
	v125_:setField(field)
	v125_:setFruit(FruitType.UNKNOWN, 0)
	v125_:setWeedState(0)
	v125_:setStoneLevel(0)
	v125_:setGroundAngle(field:getAngle())
	v125_:setGroundType(FieldGroundType.CULTIVATED)
	v125_:setSprayType(FieldGroundType.NONE)
	v125_:clearHeight()
	self:logNPCAction("FieldManager: Cultivate field \'%s\'", field:getName())
	self:addFieldUpdateTask(v125_)
	return v125_
end

-- Local values: fieldState, fruitTypeDesc, task, limeLevel, plowLevel
function FieldManager:harvestField(field)
	local v128_ = field:getFieldState()
	local v129_ = g_fruitTypeManager:getFruitTypeByIndex(v128_.fruitTypeIndex)
	local v130_ = FieldUpdateTask.new()
	v130_:setField(field)
	v130_:setFruit(v128_.fruitTypeIndex, v129_.cutState)
	v130_:setWeedState(0)
	v130_:setGroundAngle(field:getAngle())
	v130_:setSprayType(FieldSprayType.NONE)
	v130_:clearHeight()
	if v129_.consumesLime then
		local v131_ = v128_.limeLevel - 1
		local v132_ = math.max(v131_, 0)
		if v132_ ~= v128_.limeLevel then
			v130_:setLimeLevel(v132_)
		end
	end
	if v129_.increasesSoilDensity then
		local v133_ = v128_.plowLevel - 1
		local v134_ = math.max(v133_, 0)
		if v134_ ~= v128_.plowLevel then
			v130_:setPlowLevel(v134_)
		end
	end
	self:logNPCAction("FieldManager: Harvest field \'%s\'", field:getName())
	self:addFieldUpdateTask(v130_)
	return v130_
end

-- Local values: fruitTypeDesc, task, name
function FieldManager:sowField(field, fruitTypeIndex)
	local v138_ = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	local v139_ = FieldUpdateTask.new()
	v139_:setField(field)
	v139_:setFruit(fruitTypeIndex, 1)
	v139_:setGroundAngle(field:getAngle())
	v139_:setGroundType(v138_:getDefaultSowingGroundType())
	v139_:setSprayType(FieldSprayType.NONE)
	v139_:setStoneLevel(0)
	v139_:setWeedState(v138_.plantsWeed and 1 or 0)
	v139_:clearHeight()
	local v140_ = g_fruitTypeManager:getFruitTypeNameByIndex(fruitTypeIndex)
	self:logNPCAction("FieldManager: Sow field \'%s\' with \'%s\'", field:getName(), v140_)
	self:addFieldUpdateTask(v139_)
	return v139_
end

-- Local values: fieldState, newSprayLevel, task
function FieldManager:fertilizeField(field)
	local v143_ = field:getFieldState().sprayLevel + 1
	local v144_ = self.sprayLevelMaxValue
	local v145_ = math.max(v143_, v144_)
	local v146_ = FieldUpdateTask.new()
	v146_:setField(field)
	v146_:setSprayType(FieldSprayType.FERTILIZER)
	v146_:setSprayLevel(v145_)
	self:logNPCAction("FieldManager: Fertilize field \'%s\'", field:getName())
	self:addFieldUpdateTask(v146_)
	return v146_
end

-- Local values: task
function FieldManager:limeField(field)
	local v149_ = FieldUpdateTask.new()
	v149_:setField(field)
	v149_:setFruit(FruitType.UNKNOWN, 0)
	v149_:setWeedState(0)
	v149_:setStoneLevel(0)
	v149_:setGroundAngle(field:getAngle())
	v149_:setGroundType(FieldGroundType.CULTIVATED)
	v149_:setLimeLevel(self.limeLevelMaxValue)
	v149_:setSprayType(FieldSprayType.LIME)
	v149_:clearHeight()
	self:logNPCAction("FieldManager: Lime field \'%s\'", field:getName())
	self:addFieldUpdateTask(v149_)
	return v149_
end

-- Local values: field
function FieldManager:addFieldUpdateTask(updateTask, immediate)
	if immediate then
		updateTask:start(true)
		updateTask:update(1)
		self:onFinishFieldUpdateTask(updateTask)
		return
	elseif g_server == nil and self.mission.isLoaded then
		Logging.error("Trying to add non-immediate field update task on client")
		printCallstack()
	else
		local v153_ = self.updateTasks
		table.insert(v153_, updateTask)
		if updateTask.getField ~= nil then
			local v154_ = updateTask:getField()
			if v154_ ~= nil then
				self.fieldNumUpdateTasks[v154_] = self.fieldNumUpdateTasks[v154_] + 1
			end
		end
	end
end

-- Local values: field
function FieldManager:onFinishFieldUpdateTask(updateTask)
	if updateTask.getField ~= nil then
		local v157_ = updateTask:getField()
		if v157_ ~= nil then
			local v158_ = self.fieldNumUpdateTasks
			local v159_ = self.fieldNumUpdateTasks[v157_] - 1
			v158_[v157_] = math.max(v159_, 0)
			v157_:updateState()
		end
	end
end

-- Local values: _, field, mission, needUpdate, i, task
function FieldManager:setPendingFieldUpdates()
	table.clear(self.pendingFieldUpdates)
	table.clear(self.pendingFieldUpdatesMapping)
	for _, v161_ in ipairs(self.fields) do
		if not v161_:getHasOwner() then
			local v162_ = v161_.currentMission
			if v162_ == nil and true or not v162_:getWasStarted() then
				local v163_ = self.pendingFieldUpdates
				table.insert(v163_, v161_)
				self.pendingFieldUpdatesMapping[v161_] = true
				for v164_ = #self.updateTasks, 1, -1 do
					local v165_ = self.updateTasks[v164_]
					if v165_:getField() == v161_ then
						table.remove(self.updateTasks, v164_)
						self:onFinishFieldUpdateTask(v165_)
						Logging.devInfo("FieldManager: Remove pending update task \'%s\' for field \'%d\'", tostring(v165_), v161_:getId())
					end
				end
			end
		end
	end
	Utils.shuffle(self.pendingFieldUpdates)
	self.currentUpdateTask = nil
end

function FieldManager:getFieldForMission()
	return self.debugField or self.currentMissionField
end

function FieldManager:onFieldMissionStarted()
	self.currentMissionField = self:generateFieldForMission()
end

function FieldManager:onFieldMissionDeleted() end

-- Local values: numFields, start, i, fieldIndex, field
function FieldManager:generateFieldForMission()
	if g_currentMission.growthSystem:getIsGrowingInProgress() then
		return nil
	end
	local v169_ = #self.fields
	if v169_ > 0 then
		for v170_ = math.random(1, v169_), v169_ do
			local v171_
			if v169_ < v170_ then
				v171_ = v170_ - v169_
			else
				v171_ = v170_
			end
			local v172_ = self.fields[v171_]
			if self:getIsFieldReadyForMission(v172_) then
				return v172_
			end
		end
	end
	return nil
end

function FieldManager:getIsFieldReadyForMission(field)
	if self.pendingFieldUpdatesMapping[field] == nil then
		if self.fieldNumUpdateTasks[field] > 0 then
			return false
		else
			return field:getIsReadyForMission() and true or false
		end
	else
		return false
	end
end

function FieldManager:generatePlannedFruitForField(field)
	if field.grassMissionOnly then
		return FruitType.GRASS
	else
		return self.availableFruitTypeIndices[math.random(1, self.fruitTypesCount)]
	end
end

-- Local values: fruitTypeIndex, fruitTypeDesc
function FieldManager:getFruitIndexForField(field)
	local v178_ = field.plannedFruitTypeIndex
	if v178_ == nil or v178_ == FruitType.UNKNOWN then
		return nil
	elseif g_fruitTypeManager:getFruitTypeByIndex(v178_):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
		return v178_
	else
		return nil
	end
end

function FieldManager:onFinishedGrowthPeriod(period, hasPendingGrowth)
	if not hasPendingGrowth then
		self:setPendingFieldUpdates()
	end
end

function FieldManager:onMissionGenerationStart()
	self.currentMissionField = self:generateFieldForMission()
end

function FieldManager:onMissionGenerationEnd()
	self.currentMissionField = nil
end
function FieldManager.getFieldIdAtPlayerPosition()
	local v183_, _, v184_ = g_localPlayer:getPosition()
	if v183_ == nil then
		return nil
	else
		local v185_ = g_farmlandManager:getFarmlandAtWorldPosition(v183_, v184_)
		if v185_ == nil then
			return nil
		else
			return v185_:getId()
		end
	end
end

function FieldManager:consoleCommandSetFieldState(fieldId, fruitName, growthState)
	if fieldId == nil or fieldId == "nil" then
		local v189_ = FieldManager.getFieldIdAtPlayerPosition
		fieldId = tostring(v189_())
	end
	local v190_ = tonumber(growthState)
	FieldStateDialog.show(fieldId, fruitName, v190_)
end

-- Local values: numAngles, groundLayerIndex
function FieldManager:consoleCommandSetFieldGround(fieldId, groundTypeName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage)
	if fieldId == nil or fieldId == "nil" then
		local v202_ = FieldManager.getFieldIdAtPlayerPosition
		fieldId = tostring(v202_())
	end
	local v203_ = Utils.parseConsoleParameter(groundTypeName)
	local v204_ = tonumber(angle)
	if v204_ ~= nil and v204_ ~= 0 then
		local v205_ = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
		if v204_ < v205_ then
			local v206_ = 3.141592653589793 / v205_
			v204_ = v204_ * math.deg(v206_)
		end
	end
	local v207_ = Utils.parseConsoleParameter(groundLayer)
	if tonumber(v207_) ~= nil then
		local v208_ = tonumber(v207_)
		v207_ = FieldSprayType.getName(v208_ + 1)
	end
	local v209_ = tonumber(fertilizerState)
	local v210_ = tonumber(plowingState)
	local v211_ = tonumber(weedState)
	local v212_ = tonumber(limeState)
	local v213_ = tonumber(stubbleState)
	local v214_ = Utils.stringToBoolean(buyField)
	local v215_ = Utils.stringToBoolean(removeFoliage)
	FieldStateDialog.show(fieldId, nil, nil, v203_, v204_, v207_, v209_, v210_, v211_, v212_, v213_, v214_, v215_)
end

function FieldManager:consoleCommandToggleDebugFieldStatus(size)
	FieldManager.DEBUG_SHOW_FIELDSTATUS = not FieldManager.DEBUG_SHOW_FIELDSTATUS
	local v216_ = FieldManager.DEBUG_SHOW_FIELDSTATUS
	return "ToggleFieldStatus: " .. tostring(v216_)
end

function FieldManager:consoleCommandToggleDebugFieldNPCLogging(size)
	FieldManager.DEBUG_SHOW_NPC_ACTIONS = not FieldManager.DEBUG_SHOW_NPC_ACTIONS
	local v217_ = FieldManager.DEBUG_SHOW_NPC_ACTIONS
	return "ToggleFieldNPCLogging: " .. tostring(v217_)
end
g_fieldManager = FieldManager.new()
