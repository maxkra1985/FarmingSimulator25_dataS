-- Local values: FieldUpdateTask_mt
FieldUpdateTask = {}
local FieldUpdateTask_mt = Class(FieldUpdateTask, DensityMapUpdateTask)

function FieldUpdateTask.registerXMLPaths(schema, basePath)
	DensityMapUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#fieldId", "Id of the field", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".fruit#type", "Name of the fruit type", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".fruit#growthState", "Growthstate of the fruit type", nil, false)
	FieldGroundType.registerXMLPath(schema, basePath .. ".ground#type", "Name of the ground type", nil, false)
	schema:register(XMLValueType.INT, basePath .. ".ground#angle", "Angle of the ground", nil, false)
	FieldSprayType.registerXMLPath(schema, basePath .. ".spray#type", "Name of the spray type", nil, false)
	schema:register(XMLValueType.INT, basePath .. ".spray#level", "Level of the spray", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#weedState", "Weed state", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#stoneLevel", "Stone level", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#plowLevel", "Plow level", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#limeLevel", "Lime level", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#rollerLevel", "Roller level", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#stubbleShredLevel", "Stubbleshred level", nil, false)
	FieldType.registerXMLPath(schema, basePath .. "#fieldType", "Name of the field type", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#clearHeight", "Clear tip anything", nil, false)
end

-- Upvalues: FieldUpdateTask_mt
-- Local values: self
function FieldUpdateTask.new(customMt)
	-- upvalues: (copy) FieldUpdateTask_mt
	local v5_ = FieldUpdateTask:superClass().new(customMt or FieldUpdateTask_mt)
	v5_.fieldId = nil
	v5_.multiModifier = DensityMapMultiModifier.new()
	v5_.filter1 = nil
	v5_.filter2 = nil
	v5_.filter3 = nil
	return v5_
end

-- Local values: fruitTypeDesc, growthStateName
function FieldUpdateTask:saveToXMLFile(xmlFile, key)
	FieldUpdateTask:superClass().saveToXMLFile(self, xmlFile, key)
	if self.fieldId ~= nil then
		xmlFile:setValue(key .. "#fieldId", self.fieldId)
	end
	if self.fruitTypeIndex ~= nil then
		local v9_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		xmlFile:setValue(key .. ".fruit#type", v9_ == nil and "UNKNOWN" or (v9_.name or "UNKNOWN"))
		if v9_ ~= nil then
			local v10_ = v9_:getGrowthStateName(self.growthState) or self.growthState
			xmlFile:setValue(key .. ".fruit#growthState", (tostring(v10_)))
		end
	end
	if self.groundType ~= nil then
		FieldGroundType.saveToXMLFile(xmlFile, key .. ".ground#type", self.groundType)
	end
	if self.groundAngle ~= nil then
		xmlFile:setValue(key .. ".ground#angle", self.groundAngle)
	end
	if self.fieldSprayType ~= nil then
		FieldSprayType.saveToXMLFile(xmlFile, key .. ".spray#type", self.fieldSprayType)
	end
	if self.sprayLevel ~= nil then
		xmlFile:setValue(key .. ".spray#level", self.sprayLevel)
	end
	if self.weedState ~= nil then
		xmlFile:setValue(key .. "#weedState", self.weedState)
	end
	if self.stoneLevel ~= nil then
		xmlFile:setValue(key .. "#stoneLevel", self.stoneLevel)
	end
	if self.plowLevel ~= nil then
		xmlFile:setValue(key .. "#plowLevel", self.plowLevel)
	end
	if self.limeLevel ~= nil then
		xmlFile:setValue(key .. "#limeLevel", self.limeLevel)
	end
	if self.rollerLevel ~= nil then
		xmlFile:setValue(key .. "#rollerLevel", self.rollerLevel)
	end
	if self.stubbleShredLevel ~= nil then
		xmlFile:setValue(key .. "#stubbleShredLevel", self.stubbleShredLevel)
	end
	if self.fieldType ~= nil then
		FieldType.saveToXMLFile(xmlFile, key .. "#fieldType", self.fieldType)
	end
	if self.doClearHeight ~= nil then
		xmlFile:setValue(key .. "#clearHeight", self.doClearHeight)
	end
end

-- Local values: fieldId, fruitTypeName, fruitType, growthState, growthStateNumber, weedState, stoneLevel, groundType, groundAngle, fieldSprayType, sprayLevel, limeLevel, rollerLevel, plowLevel, fieldType, stubbleShredLevel, doClearHeight
function FieldUpdateTask:loadFromXMLFile(xmlFile, key)
	local v14_ = xmlFile:getValue(key .. "#fieldId")
	if v14_ ~= nil then
		self.fieldId = v14_
	end
	FieldUpdateTask:superClass().loadFromXMLFile(self, xmlFile, key)
	local v15_ = xmlFile:getValue(key .. ".fruit#type")
	if v15_ ~= nil then
		local v16_ = g_fruitTypeManager:getFruitTypeByName(v15_)
		if v16_ == nil then
			if string.upper(v15_) == "UNKNOWN" then
				self:setFruit(FruitType.UNKNOWN, 0)
			end
		else
			local v17_ = xmlFile:getValue(key .. ".fruit#growthState") or 0
			local v18_ = tonumber(v17_)
			if v18_ == nil then
				if not string.isNilOrWhitespace(v17_) then
					v18_ = v16_:getGrowthStateByName(v17_)
				end
				if v18_ == nil then
					Logging.xmlWarning(xmlFile, "FieldUpdateTask: Invalid fruitTypeName \'%s\' growthstate \'%s\' for \'%s\'", v15_, v17_, key)
					return false
				end
			end
			self:setFruit(v16_.index, v18_)
		end
	end
	local v19_ = xmlFile:getValue(key .. "#weedState")
	if v19_ ~= nil then
		self:setWeedState(v19_)
	end
	local v20_ = xmlFile:getValue(key .. "#stoneLevel")
	if v20_ ~= nil then
		self:setStoneLevel(v20_)
	end
	local v21_ = FieldGroundType.loadFromXMLFile(xmlFile, key .. ".ground#type")
	if v21_ ~= nil then
		self:setGroundType(v21_)
	end
	local v22_ = xmlFile:getValue(key .. ".ground#angle")
	if v22_ ~= nil then
		self:setGroundAngle(v22_)
	end
	local v23_ = FieldSprayType.loadFromXMLFile(xmlFile, key .. ".spray#type")
	if v23_ ~= nil then
		self:setSprayType(v23_)
	end
	local v24_ = xmlFile:getValue(key .. ".spray#level")
	if v24_ ~= nil then
		self:setSprayLevel(v24_)
	end
	local v25_ = xmlFile:getValue(key .. "#limeLevel")
	if v25_ ~= nil then
		self:setLimeLevel(v25_)
	end
	local v26_ = xmlFile:getValue(key .. "#rollerLevel")
	if v26_ ~= nil then
		self:setRollerLevel(v26_)
	end
	local v27_ = xmlFile:getValue(key .. "#plowLevel")
	if v27_ ~= nil then
		self:setPlowLevel(v27_)
	end
	local v28_ = FieldType.loadFromXMLFile(xmlFile, key .. "#fieldType")
	if v28_ ~= nil then
		self:setFieldType(v28_)
	end
	local v29_ = xmlFile:getValue(key .. "#stubbleShredLevel")
	if v29_ ~= nil then
		self:setStubbleShredLevel(v29_)
	end
	if xmlFile:getValue(key .. "#clearHeight") then
		self:clearHeight()
	end
	if self.state == DensityMapUpdateTaskState.RUNNING then
		self:start()
	end
	return true
end

function FieldUpdateTask:setField(field)
	self.fieldId = field:getId()
end

-- Local values: field
function FieldUpdateTask:getField()
	return g_fieldManager:getFieldById(self.fieldId)
end

function FieldUpdateTask:addFilter(filter)
	if self.filter1 == nil then
		self.filter1 = filter
		return true
	elseif self.filter2 == nil then
		self.filter2 = filter
		return true
	elseif self.filter3 == nil then
		self.filter3 = filter
		return true
	else
		Logging.devWarning("Maximum number of filters is 3 for FieldUpdateTask")
		return false
	end
end

-- Local values: fruitTypeDesc
function FieldUpdateTask:setFruit(fruitTypeIndex, growthState)
	if fruitTypeIndex ~= nil then
		if fruitTypeIndex ~= FruitType.UNKNOWN then
			local v38_ = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
			if v38_ == nil then
				Logging.error("No fruit type for index %q", fruitTypeIndex)
				return
			end
			if v38_.terrainDataPlaneId == nil then
				Logging.error("No terrain data layer for fruitType %q", v38_.name)
				return
			end
		end
		self.fruitTypeIndex = fruitTypeIndex
		self.growthState = growthState
	end
end

-- Local values: weedSystem
function FieldUpdateTask:setWeedState(weedState)
	local v41_ = g_currentMission.weedSystem
	if v41_ ~= nil and v41_:getMapHasWeed() then
		self.weedState = weedState
	end
end

-- Local values: stoneSystem
function FieldUpdateTask:setStoneLevel(stoneLevel)
	local v44_ = g_currentMission.stoneSystem
	if v44_ ~= nil and v44_:getMapHasStones() then
		self.stoneLevel = stoneLevel
	end
end

function FieldUpdateTask:setGroundType(groundType)
	self.groundType = groundType
end

function FieldUpdateTask:setGroundAngle(groundAngle)
	self.groundAngle = groundAngle
end

function FieldUpdateTask:setSprayType(fieldSprayType)
	self.fieldSprayType = fieldSprayType
end

function FieldUpdateTask:setSprayLevel(sprayLevel)
	self.sprayLevel = sprayLevel
end

function FieldUpdateTask:setPlowLevel(plowLevel)
	if Platform.gameplay.usePlowCounter then
		self.plowLevel = plowLevel
	end
end

-- Local values: fieldGroundSystem, densityMapId, _, _
function FieldUpdateTask:setFieldType(fieldType)
	local v57_, _, _ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
	if v57_ == nil then
		Logging.warning("Current map does not support field types")
	else
		self.fieldType = fieldType
	end
end

function FieldUpdateTask:setLimeLevel(limeLevel)
	if Platform.gameplay.useLimeCounter then
		self.limeLevel = limeLevel
	end
end

function FieldUpdateTask:setRollerLevel(rollerLevel)
	if Platform.gameplay.useRolling then
		self.rollerLevel = rollerLevel
	end
end

function FieldUpdateTask:setStubbleShredLevel(stubbleShredLevel)
	if Platform.gameplay.useStubbleShred then
		self.stubbleShredLevel = stubbleShredLevel
	end
end

function FieldUpdateTask:setWaterLevel(waterLevel)
	self.waterLevel = waterLevel
end

function FieldUpdateTask:resetDisplacement()
	self.doResetDisplacement = true
end

function FieldUpdateTask:clearTireTracks()
	if g_currentMission.tireTrackSystem ~= nil then
		self.doClearTireTracks = true
	end
end

-- Local values: fruitTypeDesc, perlinFilter
function FieldUpdateTask:setPerlinFilter(fruitTypeIndex, percentage, minOctave, numOctave, persistence)
	local v74_ = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	local v75_ = PerlinNoiseFilter.new(v74_.terrainDataPlaneId, minOctave or 13, numOctave or 1, persistence or 0.5)
	v75_:setValueCompareParams(DensityValueCompareType.GREATER, (percentage or 0.5) * 10000)
	self.filter = v75_
end

function FieldUpdateTask:clearHeight()
	self.doClearHeight = true
end

-- Local values: modifier
function FieldUpdateTask:setValue(densityMapId, firstChannel, numChannels, value, filter1, filter2, filter3)
	local v85_ = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
	self.multiModifier:addExecuteSet(value, v85_, filter1, filter2, filter3)
end

-- Local values: fieldGroundSystem, densityMapId, firstChannel, numChannels, modifier
function FieldUpdateTask:setFieldGroundValue(map, value, filter1, filter2, filter3)
	local v92_, v93_, v94_ = g_currentMission.fieldGroundSystem:getDensityMapData(map)
	local v95_ = DensityMapModifier.new(v92_, v93_, v94_, g_terrainNode)
	self.multiModifier:addExecuteSet(value, v95_, filter1, filter2, filter3)
end

-- Local values: filter1, filter2, filter3, fieldGroundSystem, haulmFruitTypeDesc, fruitTypeDesc, modifier, fruitTypeDesc, weedSystem, densityMapId, firstChannel, numChannels, stoneSystem, densityMapId, firstChannel, numChannels, stoneFilter, min, _, value, value, value, value, value, terrainDetailHeightId, displacementMapId, displacementFirstChannel, displacementNumChannels, resetValue
function FieldUpdateTask:prepare()
	local v97_ = self.filter1
	local v98_ = self.filter2
	local v99_ = self.filter3
	local v100_ = g_currentMission.fieldGroundSystem
	if self.fruitTypeIndex ~= nil then
		local v101_ = g_fruitTypeManager:getFirstHaulmFruitType()
		if v101_ ~= nil then
			self:setValue(v101_.terrainDataPlaneIdHaulm, v101_.startStateChannelHaulm, v101_.numStateChannelsHaulm, 0, v97_, v98_, v99_)
		end
		if self.fruitTypeIndex == FruitType.UNKNOWN then
			local v102_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.WHEAT)
			local v103_ = DensityMapModifier.new(v102_.terrainDataPlaneId, v102_.startStateChannel, v102_.numStateChannels, g_terrainNode)
			v103_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
			self.multiModifier:addExecuteSet(0, v103_, v97_, v98_, v99_)
		else
			local v104_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
			self:setValue(v104_.terrainDataPlaneId, v104_.startStateChannel, v104_.numStateChannels, self.growthState, v97_, v98_, v99_)
		end
	end
	if self.weedState ~= nil then
		local v105_, v106_, v107_ = g_currentMission.weedSystem:getDensityMapData()
		self:setValue(v105_, v106_, v107_, self.weedState, v97_, v98_, v99_)
	end
	if self.stoneLevel ~= nil then
		local v108_ = g_currentMission.stoneSystem
		local v109_, v110_, v111_ = v108_:getDensityMapData()
		local v112_ = DensityMapFilter.new(v109_, v110_, v111_)
		local v113_, _ = v108_:getMinMaxValues()
		v112_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		local _ = self.stoneLevel
		local v114_
		if self.stoneLevel == 0 then
			v114_ = v108_:getMaskValue()
		else
			v114_ = self.stoneLevel - 1 + v113_
		end
		self:setValue(v109_, v110_, v111_, v114_, v112_, v97_, v98_)
	end
	if self.groundType ~= nil then
		local v115_ = FieldGroundType.getValueByType(self.groundType)
		self:setFieldGroundValue(FieldDensityMap.GROUND_TYPE, v115_, v97_, v98_, v99_)
	end
	if self.groundAngle ~= nil then
		local v116_ = FSDensityMapUtil.convertToDensityMapAngle(self.groundAngle, v100_:getGroundAngleMaxValue())
		self:setFieldGroundValue(FieldDensityMap.GROUND_ANGLE, v116_, v97_, v98_, v99_)
	end
	if self.fieldSprayType ~= nil then
		local v117_ = FieldSprayType.getValueByType(self.fieldSprayType)
		self:setFieldGroundValue(FieldDensityMap.SPRAY_TYPE, v117_, v97_, v98_, v99_)
	end
	if self.fieldType ~= nil then
		local v118_ = FieldType.getValueByType(self.fieldType)
		self:setFieldGroundValue(FieldDensityMap.FIELD_TYPE, v118_, v97_, v98_, v99_)
	end
	if self.sprayLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.SPRAY_LEVEL, self.sprayLevel, v97_, v98_, v99_)
	end
	if self.plowLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.PLOW_LEVEL, self.plowLevel, v97_, v98_, v99_)
	end
	if self.limeLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.LIME_LEVEL, self.limeLevel, v97_, v98_, v99_)
	end
	if self.rollerLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.ROLLER_LEVEL, self.rollerLevel, v97_, v98_, v99_)
	end
	if self.stubbleShredLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.STUBBLE_SHRED_LEVEL, self.stubbleShredLevel, v97_, v98_, v99_)
	end
	if self.waterLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.WATER_LEVEL, self.waterLevel, v97_, v98_, v99_)
	end
	if self.doClearHeight then
		local v119_ = g_currentMission.terrainDetailHeightId
		self:setValue(v119_, getDensityMapHeightFirstChannel(v119_), getDensityMapHeightNumChannels(v119_), 0, v97_, v98_, v99_)
		self:setValue(v119_, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels, 0, v97_, v98_, v99_)
	end
	if self.doResetDisplacement then
		local v120_, v121_, v122_ = v100_:getDisplacementData()
		self:setValue(v120_, v121_, v122_, v100_:getDisplacementResetValue(), v97_, v98_, v99_)
	end
end

function FieldUpdateTask:enqueue(immediate)
	g_fieldManager:addFieldUpdateTask(self, immediate)
end

-- Local values: field, multiModifier
function FieldUpdateTask:start(immediate)
	if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
		return false
	end
	if self.area == nil and self.fieldId ~= nil then
		local v127_ = g_fieldManager:getFieldById(self.fieldId)
		if v127_ ~= nil then
			self.area = v127_:getDensityMapPolygon()
		end
	end
	if self.area == nil then
		self.state = DensityMapUpdateTaskState.FINISHED
		Logging.warning("Missing area for FieldUpdateTask")
		return false
	end
	self.state = DensityMapUpdateTaskState.RUNNING
	local v128_ = self.multiModifier
	self:prepare()
	self.area:applyToModifier(v128_)
	local v129_, v130_ = v128_:getPolygonMinMaxZ()
	self.minY = v129_
	self.maxY = v130_
	if self.minY ~= nil then
		if self.currentMinY == nil then
			self.currentMinY = self.minY
			self.currentMaxY = self.minY + self.maxRegionPerFrame
		end
		if immediate then
			self.currentMinY = self.minY
			self.currentMaxY = self.maxY
		end
	end
	return true
end

-- Local values: multiModifier
function FieldUpdateTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		local v132_ = self.multiModifier
		if self.currentMinY ~= nil then
			v132_:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
		end
		v132_:execute()
		if self.minY ~= nil then
			self.currentMinY = self.currentMaxY
			local v133_ = self.currentMinY + self.maxRegionPerFrame
			local v134_ = self.maxY
			self.currentMaxY = math.min(v133_, v134_)
			if self.currentMinY ~= self.maxY then
				return
			end
		end
		if self.doClearTireTracks then
			g_currentMission.tireTrackSystem:erasePolygon(self.area:getVerticesList())
			self.doClearTireTracks = nil
		end
		self:setFinished()
	end
end

function FieldUpdateTask:getName()
	if self.customName == nil then
		if self.fieldId == nil then
			return FieldUpdateTask:superClass().getName(self)
		else
			return string.format("field \'%s\'", self.fieldId)
		end
	else
		return self.customName
	end
end
