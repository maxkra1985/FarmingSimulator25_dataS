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
function FieldUpdateTask.new(customMt)
	local self = FieldUpdateTask:superClass().new(customMt or FieldUpdateTask_mt)
	self.fieldId = nil
	self.multiModifier = DensityMapMultiModifier.new()
	self.filter1 = nil
	self.filter2 = nil
	self.filter3 = nil
	return self
end
function FieldUpdateTask:saveToXMLFile(xmlFile, key)
	FieldUpdateTask:superClass().saveToXMLFile(self, xmlFile, key)
	if self.fieldId ~= nil then
		xmlFile:setValue(key .. "#fieldId", self.fieldId)
	end
	if self.fruitTypeIndex ~= nil then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
		xmlFile:setValue(key .. ".fruit#type", fruitTypeDesc ~= nil and fruitTypeDesc.name or "UNKNOWN")
		if fruitTypeDesc ~= nil then
			local growthStateName = fruitTypeDesc:getGrowthStateName(self.growthState) or self.growthState
			xmlFile:setValue(key .. ".fruit#growthState", tostring(growthStateName))
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
function FieldUpdateTask:loadFromXMLFile(xmlFile, key)
	local fieldId = xmlFile:getValue(key .. "#fieldId")
	if fieldId ~= nil then
		self.fieldId = fieldId
	end
	FieldUpdateTask:superClass().loadFromXMLFile(self, xmlFile, key)
	local fruitTypeName = xmlFile:getValue(key .. ".fruit#type")
	if fruitTypeName ~= nil then
		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
		if fruitType ~= nil then
			local growthState = xmlFile:getValue(key .. ".fruit#growthState") or 0
			local growthStateNumber = tonumber(growthState)
			if growthStateNumber == nil then
				if not string.isNilOrWhitespace(growthState) then
					growthStateNumber = fruitType:getGrowthStateByName(growthState)
				end
				if growthStateNumber == nil then
					Logging.xmlWarning(xmlFile, "FieldUpdateTask: Invalid fruitTypeName '%s' growthstate '%s' for '%s'", fruitTypeName, growthState, key)
					return false
				end
			end
			self:setFruit(fruitType.index, growthStateNumber)
		elseif string.upper(fruitTypeName) == "UNKNOWN" then
			self:setFruit(FruitType.UNKNOWN, 0)
		end
	end
	local weedState = xmlFile:getValue(key .. "#weedState")
	if weedState ~= nil then
		self:setWeedState(weedState)
	end
	local stoneLevel = xmlFile:getValue(key .. "#stoneLevel")
	if stoneLevel ~= nil then
		self:setStoneLevel(stoneLevel)
	end
	local groundType = FieldGroundType.loadFromXMLFile(xmlFile, key .. ".ground#type")
	if groundType ~= nil then
		self:setGroundType(groundType)
	end
	local groundAngle = xmlFile:getValue(key .. ".ground#angle")
	if groundAngle ~= nil then
		self:setGroundAngle(groundAngle)
	end
	local fieldSprayType = FieldSprayType.loadFromXMLFile(xmlFile, key .. ".spray#type")
	if fieldSprayType ~= nil then
		self:setSprayType(fieldSprayType)
	end
	local sprayLevel = xmlFile:getValue(key .. ".spray#level")
	if sprayLevel ~= nil then
		self:setSprayLevel(sprayLevel)
	end
	local limeLevel = xmlFile:getValue(key .. "#limeLevel")
	if limeLevel ~= nil then
		self:setLimeLevel(limeLevel)
	end
	local rollerLevel = xmlFile:getValue(key .. "#rollerLevel")
	if rollerLevel ~= nil then
		self:setRollerLevel(rollerLevel)
	end
	local plowLevel = xmlFile:getValue(key .. "#plowLevel")
	if plowLevel ~= nil then
		self:setPlowLevel(plowLevel)
	end
	local fieldType = FieldType.loadFromXMLFile(xmlFile, key .. "#fieldType")
	if fieldType ~= nil then
		self:setFieldType(fieldType)
	end
	local stubbleShredLevel = xmlFile:getValue(key .. "#stubbleShredLevel")
	if stubbleShredLevel ~= nil then
		self:setStubbleShredLevel(stubbleShredLevel)
	end
	local doClearHeight = xmlFile:getValue(key .. "#clearHeight")
	if doClearHeight then
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
function FieldUpdateTask:getField()
	local field = g_fieldManager:getFieldById(self.fieldId)
	return field
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
function FieldUpdateTask:setFruit(fruitTypeIndex, growthState)
	if fruitTypeIndex == nil then
		return
	else
		if fruitTypeIndex ~= FruitType.UNKNOWN then
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
			if fruitTypeDesc == nil then
				Logging.error("No fruit type for index %q", fruitTypeIndex)
				return
			end
			if fruitTypeDesc.terrainDataPlaneId == nil then
				Logging.error("No terrain data layer for fruitType %q", fruitTypeDesc.name)
				return
			end
		end
		self.fruitTypeIndex = fruitTypeIndex
		self.growthState = growthState
	end
end
function FieldUpdateTask:setWeedState(weedState)
	local weedSystem = g_currentMission.weedSystem
	if weedSystem ~= nil and weedSystem:getMapHasWeed() then
		self.weedState = weedState
	end
end
function FieldUpdateTask:setStoneLevel(stoneLevel)
	local stoneSystem = g_currentMission.stoneSystem
	if stoneSystem ~= nil and stoneSystem:getMapHasStones() then
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
	if not Platform.gameplay.usePlowCounter then
		return
	else
		self.plowLevel = plowLevel
	end
end
function FieldUpdateTask:setFieldType(fieldType)
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local densityMapId, _, _ = fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
	if densityMapId == nil then
		Logging.warning("Current map does not support field types")
	else
		self.fieldType = fieldType
	end
end
function FieldUpdateTask:setLimeLevel(limeLevel)
	if not Platform.gameplay.useLimeCounter then
		return
	else
		self.limeLevel = limeLevel
	end
end
function FieldUpdateTask:setRollerLevel(rollerLevel)
	if not Platform.gameplay.useRolling then
		return
	else
		self.rollerLevel = rollerLevel
	end
end
function FieldUpdateTask:setStubbleShredLevel(stubbleShredLevel)
	if not Platform.gameplay.useStubbleShred then
		return
	else
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
function FieldUpdateTask:setPerlinFilter(fruitTypeIndex, percentage, minOctave, numOctave, persistence)
	percentage = percentage or 0.5
	minOctave = minOctave or 13
	numOctave = numOctave or 1
	persistence = persistence or 0.5
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	local perlinFilter = PerlinNoiseFilter.new(fruitTypeDesc.terrainDataPlaneId, minOctave, numOctave, persistence)
	perlinFilter:setValueCompareParams(DensityValueCompareType.GREATER, percentage * 10000)
	self.filter = perlinFilter
end
function FieldUpdateTask:clearHeight()
	self.doClearHeight = true
end
function FieldUpdateTask:setValue(densityMapId, firstChannel, numChannels, value, filter1, filter2, filter3)
	local modifier = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
	self.multiModifier:addExecuteSet(value, modifier, filter1, filter2, filter3)
end
function FieldUpdateTask:setFieldGroundValue(map, value, filter1, filter2, filter3)
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local densityMapId, firstChannel, numChannels = fieldGroundSystem:getDensityMapData(map)
	local modifier = DensityMapModifier.new(densityMapId, firstChannel, numChannels, g_terrainNode)
	self.multiModifier:addExecuteSet(value, modifier, filter1, filter2, filter3)
end
function FieldUpdateTask:prepare()
	local filter1 = self.filter1
	local filter2 = self.filter2
	local filter3 = self.filter3
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	if self.fruitTypeIndex ~= nil then
		local haulmFruitTypeDesc = g_fruitTypeManager:getFirstHaulmFruitType()
		if haulmFruitTypeDesc ~= nil then
			self:setValue(haulmFruitTypeDesc.terrainDataPlaneIdHaulm, haulmFruitTypeDesc.startStateChannelHaulm, haulmFruitTypeDesc.numStateChannelsHaulm, 0, filter1, filter2, filter3)
		end
		if self.fruitTypeIndex == FruitType.UNKNOWN then
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.WHEAT)
			local modifier = DensityMapModifier.new(fruitTypeDesc.terrainDataPlaneId, fruitTypeDesc.startStateChannel, fruitTypeDesc.numStateChannels, g_terrainNode)
			modifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
			self.multiModifier:addExecuteSet(0, modifier, filter1, filter2, filter3)
		else
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
			self:setValue(fruitTypeDesc.terrainDataPlaneId, fruitTypeDesc.startStateChannel, fruitTypeDesc.numStateChannels, self.growthState, filter1, filter2, filter3)
		end
	end
	if self.weedState ~= nil then
		local weedSystem = g_currentMission.weedSystem
		local densityMapId, firstChannel, numChannels = weedSystem:getDensityMapData()
		self:setValue(densityMapId, firstChannel, numChannels, self.weedState, filter1, filter2, filter3)
	end
	if self.stoneLevel ~= nil then
		local stoneSystem = g_currentMission.stoneSystem
		local densityMapId, firstChannel, numChannels = stoneSystem:getDensityMapData()
		local stoneFilter = DensityMapFilter.new(densityMapId, firstChannel, numChannels)
		local min, _ = stoneSystem:getMinMaxValues()
		stoneFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		local value = self.stoneLevel
		if self.stoneLevel == 0 then
			value = stoneSystem:getMaskValue()
		else
			value = self.stoneLevel - 1 + min
		end
		self:setValue(densityMapId, firstChannel, numChannels, value, stoneFilter, filter1, filter2)
	end
	if self.groundType ~= nil then
		local value = FieldGroundType.getValueByType(self.groundType)
		self:setFieldGroundValue(FieldDensityMap.GROUND_TYPE, value, filter1, filter2, filter3)
	end
	if self.groundAngle ~= nil then
		local value = FSDensityMapUtil.convertToDensityMapAngle(self.groundAngle, fieldGroundSystem:getGroundAngleMaxValue())
		self:setFieldGroundValue(FieldDensityMap.GROUND_ANGLE, value, filter1, filter2, filter3)
	end
	if self.fieldSprayType ~= nil then
		local value = FieldSprayType.getValueByType(self.fieldSprayType)
		self:setFieldGroundValue(FieldDensityMap.SPRAY_TYPE, value, filter1, filter2, filter3)
	end
	if self.fieldType ~= nil then
		local value = FieldType.getValueByType(self.fieldType)
		self:setFieldGroundValue(FieldDensityMap.FIELD_TYPE, value, filter1, filter2, filter3)
	end
	if self.sprayLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.SPRAY_LEVEL, self.sprayLevel, filter1, filter2, filter3)
	end
	if self.plowLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.PLOW_LEVEL, self.plowLevel, filter1, filter2, filter3)
	end
	if self.limeLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.LIME_LEVEL, self.limeLevel, filter1, filter2, filter3)
	end
	if self.rollerLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.ROLLER_LEVEL, self.rollerLevel, filter1, filter2, filter3)
	end
	if self.stubbleShredLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.STUBBLE_SHRED_LEVEL, self.stubbleShredLevel, filter1, filter2, filter3)
	end
	if self.waterLevel ~= nil then
		self:setFieldGroundValue(FieldDensityMap.WATER_LEVEL, self.waterLevel, filter1, filter2, filter3)
	end
	if self.doClearHeight then
		local terrainDetailHeightId = g_currentMission.terrainDetailHeightId
		self:setValue(terrainDetailHeightId, getDensityMapHeightFirstChannel(terrainDetailHeightId), getDensityMapHeightNumChannels(terrainDetailHeightId), 0, filter1, filter2, filter3)
		self:setValue(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels, 0, filter1, filter2, filter3)
	end
	if self.doResetDisplacement then
		local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
		local resetValue = fieldGroundSystem:getDisplacementResetValue()
		self:setValue(displacementMapId, displacementFirstChannel, displacementNumChannels, resetValue, filter1, filter2, filter3)
	end
end
function FieldUpdateTask:enqueue(immediate)
	g_fieldManager:addFieldUpdateTask(self, immediate)
end
function FieldUpdateTask:start(immediate)
	if self.state == DensityMapUpdateTaskState.RUNNING or self.state == DensityMapUpdateTaskState.FINISHED then
		return false
	end
	if self.area == nil and self.fieldId ~= nil then
		local field = g_fieldManager:getFieldById(self.fieldId)
		if field ~= nil then
			self.area = field:getDensityMapPolygon()
		end
	end
	if self.area == nil then
		self.state = DensityMapUpdateTaskState.FINISHED
		Logging.warning("Missing area for FieldUpdateTask")
		return false
	else
		self.state = DensityMapUpdateTaskState.RUNNING
		local multiModifier = self.multiModifier
		self:prepare()
		self.area:applyToModifier(multiModifier)
		self.minY, self.maxY = multiModifier:getPolygonMinMaxZ()
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
end
function FieldUpdateTask:update(dt)
	if self.state == DensityMapUpdateTaskState.RUNNING then
		local multiModifier = self.multiModifier
		if self.currentMinY ~= nil then
			multiModifier:setPolygonClipRegion(self.currentMinY, self.currentMaxY)
		end
		multiModifier:execute()
		if self.minY ~= nil then
			self.currentMinY = self.currentMaxY
			self.currentMaxY = math.min(self.currentMinY + self.maxRegionPerFrame, self.maxY)
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
	if self.customName ~= nil then
		return self.customName
	elseif self.fieldId ~= nil then
		return string.format("field '%s'", self.fieldId)
	else
		return FieldUpdateTask:superClass().getName(self)
	end
end
