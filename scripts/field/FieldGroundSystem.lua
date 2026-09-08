-- Local values: FieldGroundSystem_mt
FieldGroundSystem = {}
FieldDensityMap = {}
FieldDensityMap.GROUND_TYPE = 1
FieldDensityMap.GROUND_ANGLE = 2
FieldDensityMap.SPRAY_TYPE = 3
FieldDensityMap.SPRAY_LEVEL = 4
FieldDensityMap.LIME_LEVEL = 5
FieldDensityMap.PLOW_LEVEL = 6
FieldDensityMap.STUBBLE_SHRED_LEVEL = 7
FieldDensityMap.ROLLER_LEVEL = 8
FieldDensityMap.WATER_LEVEL = 9
FieldDensityMap.FIELD_TYPE = 10
local FieldGroundSystem_mt = Class(FieldGroundSystem)

-- Upvalues: FieldGroundSystem_mt
-- Local values: self
function FieldGroundSystem.new(customMt)
	-- upvalues: (copy) FieldGroundSystem_mt
	local v3_ = customMt or FieldGroundSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.baseDirectory = ""
	v4_:initDataStructures()
	return v4_
end

function FieldGroundSystem:initDataStructures()
	self.fieldGroundTypeValue = {}
	self.fieldGroundTypeValueToId = {}
	self.fieldGroundTypeTyreTrackColor = {}
	self.fieldSprayTypeValue = {}
	self.fieldSprayTypeTyreTrackColor = {}
	self.fieldChopperTypeValue = {}
	self.fieldChopperTypeTyreTrackColor = {}
	self.fieldTypeValue = {}
	self.densityMaps = {}
end

-- Local values: xmlFile, _
function FieldGroundSystem:loadGroundTypes(filename)
	local v8_ = XMLFile.load("fieldGround", filename)
	if v8_ == nil then
		Logging.error("Could not load field ground type xml file at %q", filename)
	else
		self:loadDensityMapFromXML(FieldDensityMap.GROUND_TYPE, v8_, "fieldGround.densityMaps.groundTypes")
		self:loadDensityMapFromXML(FieldDensityMap.GROUND_ANGLE, v8_, "fieldGround.densityMaps.groundAngle")
		self:loadDensityMapFromXML(FieldDensityMap.SPRAY_TYPE, v8_, "fieldGround.densityMaps.sprayTypes")
		self:loadDensityMapFromXML(FieldDensityMap.SPRAY_LEVEL, v8_, "fieldGround.densityMaps.sprayLevel", 3)
		self:loadDensityMapFromXML(FieldDensityMap.WATER_LEVEL, v8_, "fieldGround.densityMaps.water")
		if Platform.gameplay.usePlowCounter then
			self:loadDensityMapFromXML(FieldDensityMap.PLOW_LEVEL, v8_, "fieldGround.densityMaps.plowLevel")
		end
		if Platform.gameplay.useLimeCounter then
			self:loadDensityMapFromXML(FieldDensityMap.LIME_LEVEL, v8_, "fieldGround.densityMaps.limeLevel")
		end
		if Platform.gameplay.useStubbleShred then
			self:loadDensityMapFromXML(FieldDensityMap.STUBBLE_SHRED_LEVEL, v8_, "fieldGround.densityMaps.stubbleShredLevel")
		end
		if Platform.gameplay.useRolling then
			self:loadDensityMapFromXML(FieldDensityMap.ROLLER_LEVEL, v8_, "fieldGround.densityMaps.rollerLevel")
		end
		self:loadDensityMapFromXML(FieldDensityMap.FIELD_TYPE, v8_, "fieldGround.densityMaps.fieldType")
		local _, v9_, v10_ = self:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.groundTypesFirstChannel = v9_
		self.groundTypesNumChannels = v10_
		self.groundTypesMaxValue = self:getMaxValue(FieldDensityMap.GROUND_TYPE)
		local v11_ = 2 ^ self.groundTypesNumChannels - 1
		local v12_ = self.groundTypesFirstChannel
		self.groundMask = bit32.lshift(v11_, v12_)
		local _, v13_, v14_ = self:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		self.angleFirstChannel = v13_
		self.angleNumChannels = v14_
		self.angleMaxValue = self:getMaxValue(FieldDensityMap.GROUND_ANGLE)
		self.angleStep = 3.141592653589793 / 2 ^ self.angleNumChannels
		local _, v15_, v16_ = self:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		self.sprayTypesFirstChannel = v15_
		self.sprayTypesNumChannels = v16_
		self.sprayTypesMaxValue = self:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		local v17_ = 2 ^ self.sprayTypesNumChannels - 1
		local v18_ = self.sprayTypesFirstChannel
		self.sprayMask = bit32.lshift(v17_, v18_)
		self.fieldTypesMaxValue = self:getMaxValue(FieldDensityMap.FIELD_TYPE)
		self:loadGroundIdFromXML(FieldGroundType.STUBBLE_TILLAGE, v8_, "fieldGround.densityMaps.groundTypes.stubbleTillage", FieldGroundType.STUBBLE_TILLAGE, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.CULTIVATED, v8_, "fieldGround.densityMaps.groundTypes.cultivated", FieldGroundType.CULTIVATED, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.SEEDBED, v8_, "fieldGround.densityMaps.groundTypes.seedbed", FieldGroundType.SEEDBED, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.ROLLED_SEEDBED, v8_, "fieldGround.densityMaps.groundTypes.rolledSeedbed", FieldGroundType.ROLLED_SEEDBED, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.PLOWED, v8_, "fieldGround.densityMaps.groundTypes.plowed", FieldGroundType.PLOWED, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.SOWN, v8_, "fieldGround.densityMaps.groundTypes.sown", FieldGroundType.SOWN, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.DIRECT_SOWN, v8_, "fieldGround.densityMaps.groundTypes.directSown", FieldGroundType.DIRECT_SOWN, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.PLANTED, v8_, "fieldGround.densityMaps.groundTypes.planted", FieldGroundType.PLANTED, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.RIDGE, v8_, "fieldGround.densityMaps.groundTypes.ridge", FieldGroundType.RIDGE, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.RIDGE_SOWN, v8_, "fieldGround.densityMaps.groundTypes.ridgeSown", FieldGroundType.RIDGE_SOWN, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.ROLLER_LINES, v8_, "fieldGround.densityMaps.groundTypes.rollerLines", FieldGroundType.ROLLER_LINES, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.HARVEST_READY, v8_, "fieldGround.densityMaps.groundTypes.harvestReady", FieldGroundType.HARVEST_READY, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.HARVEST_READY_OTHER, v8_, "fieldGround.densityMaps.groundTypes.harvestReadyOther", FieldGroundType.HARVEST_READY_OTHER, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.GRASS, v8_, "fieldGround.densityMaps.groundTypes.grass", FieldGroundType.GRASS, {
			1,
			1,
			1,
			1
		})
		self:loadGroundIdFromXML(FieldGroundType.GRASS_CUT, v8_, "fieldGround.densityMaps.groundTypes.grassCut", FieldGroundType.GRASS_CUT, {
			1,
			1,
			1,
			1
		})
		self:loadSprayIdFromXML(FieldSprayType.FERTILIZER, v8_, "fieldGround.densityMaps.sprayTypes.fertilizer", FieldSprayType.FERTILIZER, {
			1,
			1,
			1,
			1
		})
		self:loadSprayIdFromXML(FieldSprayType.MANURE, v8_, "fieldGround.densityMaps.sprayTypes.manure", FieldSprayType.MANURE, {
			1,
			1,
			1,
			1
		})
		self:loadSprayIdFromXML(FieldSprayType.LIQUID_MANURE, v8_, "fieldGround.densityMaps.sprayTypes.liquidManure", FieldSprayType.LIQUID_MANURE, {
			1,
			1,
			1,
			1
		})
		if Platform.gameplay.useLimeCounter then
			self:loadSprayIdFromXML(FieldSprayType.LIME, v8_, "fieldGround.densityMaps.sprayTypes.lime", FieldSprayType.LIME, {
				1,
				1,
				1,
				1
			})
		end
		self:loadChopperIdFromXML(FieldChopperType.CHOPPER_STRAW, v8_, "fieldGround.densityMaps.sprayTypes.straw", 5, {
			1,
			1,
			1,
			1
		})
		self:loadChopperIdFromXML(FieldChopperType.CHOPPER_MAIZE, v8_, "fieldGround.densityMaps.sprayTypes.maize", 6, {
			1,
			1,
			1,
			1
		})
		self:loadFieldTypeIdFromXML(FieldType.DEFAULT, v8_, "fieldGround.densityMaps.fieldType.default", 0)
		self:loadFieldTypeIdFromXML(FieldType.RICE, v8_, "fieldGround.densityMaps.fieldType.rice", 1)
		self.firstSowableValue = v8_:getInt("fieldGround.densityMaps.groundTypes.ranges.sowable#firstValue", self.firstSowableValue or self.fieldGroundTypeValue[FieldGroundType.STUBBLE_TILLAGE])
		self.lastSowableValue = v8_:getInt("fieldGround.densityMaps.groundTypes.ranges.sowable#lastValue", self.lastSowableValue or self.fieldGroundTypeValue[FieldGroundType.RIDGE])
		self.firstSowingValue = v8_:getInt("fieldGround.densityMaps.groundTypes.ranges.sowing#firstValue", self.firstSowingValue or self.fieldGroundTypeValue[FieldGroundType.SOWN])
		self.lastSowingValue = v8_:getInt("fieldGround.densityMaps.groundTypes.ranges.sowing#lastValue", self.lastSowingValue or self.fieldGroundTypeValue[FieldGroundType.RIDGE_SOWN])
		v8_:delete()
	end
end

-- Local values: filename
function FieldGroundSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory
	self:loadGroundTypes("data/maps/maps_fieldGround.xml")
	local v22_ = getXMLString(xmlFile, "map.fieldGround#filename")
	if v22_ ~= nil then
		self:loadGroundTypes((Utils.getFilename(v22_, baseDirectory)))
	end
	return true
end

-- Local values: _, data
function FieldGroundSystem:delete()
	for _, v24_ in pairs(self.densityMaps) do
		if v24_.map ~= nil and v24_.canBeDeleted then
			delete(v24_.map)
		end
	end
	self.densityMaps = {}
end

-- Local values: identifier, data, size, path, missionInfo, loadFromSave, needDefaultMap, _
function FieldGroundSystem:initTerrain(mission, terrainNode, terrainDetailId)
	for _, v29_ in pairs(self.densityMaps) do
		if v29_.useTerrainDetailId then
			v29_.map = terrainDetailId
			local v30_ = getDensityMapSize(terrainDetailId)
			v29_.width = v30_
			v29_.height = v30_
			v29_.filename = getDensityMapFilename(terrainDetailId)
			v29_.isBitVector = false
			v29_.canBeDeleted = false
			v29_.usedByTerrainVT = true
		else
			v29_.map = createBitVectorMap("densityMap_fieldGroundSystem_" .. (v29_.filename or ""))
			local v31_ = v29_.path
			local v32_ = mission.missionInfo
			local v33_ = false
			local v34_
			if v32_.isValid and v29_.filename ~= nil then
				v31_ = v32_.savegameDirectory .. "/" .. v29_.filename
				v34_ = true
			else
				v34_ = false
			end
			if v34_ and not loadBitVectorMapFromFile(v29_.map, v31_, v29_.numChannels) then
				Logging.warning("Loading density map file \'" .. tostring(v31_) .. "\' failed! Loading default density map.")
				v34_ = false
			end
			if not v34_ then
				if v29_.path == nil then
					v33_ = true
				elseif not loadBitVectorMapFromFile(v29_.map, v29_.path, v29_.numChannels) then
					local v35_ = Logging.error
					local v36_ = v29_.path
					v35_("Loading default density map file \'" .. tostring(v36_) .. "\' failed!")
					v33_ = true
				end
			end
			if v33_ then
				loadBitVectorMapNew(v29_.map, 1024, 1024, v29_.numChannels, false)
				Logging.error("Missing field density map data for \'%s\'! Creating empty default", v29_.key)
			end
			local v37_, v38_ = getBitVectorMapSize(v29_.map)
			v29_.width = v37_
			v29_.height = v38_
			v29_.isBitVector = true
			v29_.canBeDeleted = true
		end
	end
	local v39_, _ = getTerrainDataPlaneByName(terrainNode, "terrainDisplacement")
	self.displacementId = v39_
	self.displacementNumChannels = getTerrainDetailNumChannels(self.displacementId)
	self.displacementResetValue = 2 ^ (self.displacementNumChannels - 1)
	local v40_, _ = getTerrainDataPlaneByName(terrainNode, "terrainDisplacementCustomFlag")
	self.displacementCustomFlagId = v40_
end

-- Local values: added, identifier, data
function FieldGroundSystem:addDensityMapSyncer(densityMapSyncer)
	local v43_ = {}
	for _, v44_ in pairs(self.densityMaps) do
		if v43_[v44_.map] == nil and v44_.syncOverNetwork then
			densityMapSyncer:addDensityMap(v44_.map, v44_.usedByTerrainVT)
			v43_[v44_.map] = true
		end
	end
	if v43_[self.displacementId] == nil then
		densityMapSyncer:addDensityMap(self.displacementId, true, 16, 100, 100)
		v43_[self.displacementId] = true
	end
end

function FieldGroundSystem:getDensityMaps()
	return self.densityMaps
end

-- Local values: data, filename, maxChannelValue, maxValue, newValue
function FieldGroundSystem:loadDensityMapFromXML(identifier, xmlFile, key, forcedMaxValue, syncOverNetwork)
	if xmlFile:hasProperty(key) then
		local v52_ = self.densityMaps[identifier] or {}
		v52_.syncOverNetwork = xmlFile:getBool(key .. "#syncOverNetwork", Utils.getNoNil(syncOverNetwork, true))
		v52_.firstChannel = xmlFile:getInt(key .. "#firstChannel") or (v52_.firstChannel or 0)
		v52_.numChannels = xmlFile:getInt(key .. "#numChannels") or (v52_.numChannels or 0)
		v52_.canBeDeleted = Utils.getNoNil(v52_.canBeDeleted, Utils.getNoNil(v52_.canBeDeleted, false))
		v52_.useTerrainDetailId = Utils.getNoNil(xmlFile:getBool(key .. "#useDefaultTerrainDetail"), Utils.getNoNil(v52_.useTerrainDetailId, false))
		if not v52_.useTerrainDetailId then
			local v53_ = xmlFile:getString(key .. "#filename")
			if v53_ ~= nil then
				v52_.path = Utils.getFilename(v53_, self.baseDirectory)
				v52_.filename = Utils.getFilenameFromPath(v52_.path)
			end
			if v52_.path == nil then
				Logging.xmlError(xmlFile, "Invalid file given for densityMap in \'%s\'. Using default terrain detail instead", key)
				v52_.useTerrainDetailId = true
			end
		end
		local v54_ = 2 ^ v52_.numChannels - 1
		local v55_ = v52_.maxValue or v54_
		local v56_ = math.max(v55_, v54_)
		local v57_ = xmlFile:getInt(key .. "#maxValue")
		if v57_ ~= nil then
			v56_ = math.min(v57_, v54_)
		end
		if forcedMaxValue ~= nil then
			v56_ = math.min(v56_, forcedMaxValue)
		end
		v52_.maxValue = v56_
		v52_.key = key
		self.densityMaps[identifier] = v52_
		return true
	end
end

-- Local values: id, colorStr, color
function FieldGroundSystem:loadGroundIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
	local v64_ = xmlFile:getInt(key .. "#value") or self.fieldGroundTypeValue[identifier]
	if v64_ == nil then
		Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
	else
		defaultValue = v64_
	end
	if self.groundTypesMaxValue < defaultValue then
		Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
		defaultValue = 0
	end
	self.fieldGroundTypeValue[identifier] = defaultValue
	self.fieldGroundTypeValueToId[defaultValue] = identifier
	local v65_ = xmlFile:getString(key .. "#tireTrackColor")
	local v66_
	if v65_ == nil then
		v66_ = nil
	else
		v66_ = string.getVector(v65_)
		if #v66_ ~= 4 then
			Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element \'%s\'!", key)
			v66_ = nil
		end
	end
	self.fieldGroundTypeTyreTrackColor[defaultValue] = v66_ or (self.fieldGroundTypeTyreTrackColor[defaultValue] or defaultColor)
end

-- Local values: id, colorStr, color
function FieldGroundSystem:loadSprayIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
	if xmlFile:hasProperty(key) then
		local v73_ = xmlFile:getInt(key .. "#value") or self.fieldSprayTypeValue[identifier]
		if v73_ == nil then
			Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
		else
			defaultValue = v73_
		end
		if defaultValue == self.sprayTypesMaxValue then
			Logging.xmlError(xmlFile, "Value \'%d\' is reserved and cannot be used in xml element \'%s\'! Using value \'0\'", self.sprayTypesMaxValue, key)
			defaultValue = 0
		end
		if self.sprayTypesMaxValue < defaultValue then
			Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
			defaultValue = 0
		end
		self.fieldSprayTypeValue[identifier] = defaultValue
		local v74_ = xmlFile:getString(key .. "#tireTrackColor")
		local v75_
		if v74_ == nil then
			v75_ = nil
		else
			v75_ = string.getVector(v74_)
			if #v75_ ~= 4 then
				Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element \'%s\'!", key)
				v75_ = nil
			end
		end
		self.fieldSprayTypeTyreTrackColor[defaultValue] = v75_ or (self.fieldSprayTypeTyreTrackColor[defaultValue] or defaultColor)
	end
end

-- Local values: id, colorStr, color
function FieldGroundSystem:loadChopperIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
	if xmlFile:hasProperty(key) then
		local v82_ = xmlFile:getInt(key .. "#value") or self.fieldChopperTypeValue[identifier]
		if v82_ == nil then
			Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
		else
			defaultValue = v82_
		end
		if defaultValue == self.sprayTypesMaxValue then
			Logging.xmlError(xmlFile, "Value \'%d\' is reserved and cannot be used in xml element \'%s\'! Using value \'0\'", self.sprayTypesMaxValue, key)
			defaultValue = 0
		end
		if self.sprayTypesMaxValue < defaultValue then
			Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
			defaultValue = 0
		end
		self.fieldChopperTypeValue[identifier] = defaultValue
		local v83_ = xmlFile:getString(key .. "#tireTrackColor")
		local v84_
		if v83_ == nil then
			v84_ = nil
		else
			v84_ = string.getVector(v83_)
			if #v84_ ~= 4 then
				Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element \'%s\'!", key)
				v84_ = nil
			end
		end
		self.fieldChopperTypeTyreTrackColor[defaultValue] = v84_ or (self.fieldChopperTypeTyreTrackColor[defaultValue] or defaultColor)
	end
end

-- Local values: id
function FieldGroundSystem:loadFieldTypeIdFromXML(identifier, xmlFile, key, defaultValue)
	if xmlFile:hasProperty(key) then
		local v90_ = xmlFile:getInt(key .. "#value") or self.fieldTypeValue[identifier]
		if v90_ == nil then
			Logging.xmlWarning(xmlFile, "Missing xml element \'%s\'! Using default value \'%d\'", key, defaultValue)
		else
			defaultValue = v90_
		end
		if self.fieldTypesMaxValue < defaultValue then
			Logging.xmlError(xmlFile, "Invalid value for xml element \'%s\'! Using value \'0\'", key)
			defaultValue = 0
		end
		self.fieldTypeValue[identifier] = defaultValue
	end
end

-- Local values: groundType
function FieldGroundSystem:getFieldGroundValueByName(groundTypeName)
	local v93_ = FieldGroundType.getByName(groundTypeName)
	if v93_ == nil then
		return nil
	else
		return self.fieldGroundTypeValue[v93_]
	end
end

-- Local values: value
function FieldGroundSystem:getFieldGroundValue(groundType)
	return self.fieldGroundTypeValue[groundType] or 0
end

function FieldGroundSystem:getFieldGroundTypeByValue(value)
	return self.fieldGroundTypeValueToId[value] or FieldGroundType.NONE
end

-- Local values: groundType, sprayType, color
function FieldGroundSystem:getFieldGroundTyreTrackColor(densityBits)
	local v100_ = self.groundMask
	local v101_ = bit32.band(densityBits, v100_)
	local v102_ = self.groundTypesFirstChannel
	local v103_ = bit32.rshift(v101_, v102_)
	local v104_ = self.sprayMask
	local v105_ = bit32.band(densityBits, v104_)
	local v106_ = self.sprayTypesFirstChannel
	local v107_ = bit32.rshift(v105_, v106_)
	local v108_ = self.fieldGroundTypeTyreTrackColor[v103_ + 1]
	if v107_ > 0 then
		v108_ = self.fieldSprayTypeTyreTrackColor[v107_]
		if v108_ == nil then
			v108_ = self.fieldChopperTypeTyreTrackColor[v107_]
		end
	end
	if v108_ == nil then
		return 0, 0, 0, 0
	else
		return v108_[1], v108_[2], v108_[3], v108_[4]
	end
end

-- Local values: sprayType
function FieldGroundSystem:getFieldSprayValueByName(sprayTypeName)
	if sprayTypeName == nil then
		return 0
	end
	local v111_ = string.upper(sprayTypeName)
	local v112_ = FieldSprayType[v111_]
	return v112_ == nil and 0 or (self.fieldSprayTypeValue[v112_] or 0)
end

-- Local values: sprayType, sprayValue
function FieldGroundSystem:getFieldSprayTypeByValue(value)
	for v115_, v116_ in pairs(self.fieldSprayTypeValue) do
		if value == v116_ then
			return v115_
		end
	end
	return FieldSprayType.NONE
end

-- Local values: value
function FieldGroundSystem:getFieldSprayValue(sprayType)
	return self.fieldSprayTypeValue[sprayType] or 0
end

-- Local values: fieldType
function FieldGroundSystem:getFieldTypeValueByName(fieldTypeName)
	local v121_ = FieldType.getByName(fieldTypeName)
	if v121_ == nil then
		return nil
	else
		return self.fieldTypeValue[v121_]
	end
end

-- Local values: value
function FieldGroundSystem:getFieldTypeValue(fieldType)
	return self.fieldTypeValue[fieldType] or 0
end

-- Local values: fieldType, fieldValue
function FieldGroundSystem:getFieldTypeByValue(value)
	for v126_, v127_ in pairs(self.fieldTypeValue) do
		if value == v127_ then
			return v126_
		end
	end
	return 0
end

function FieldGroundSystem:getSowableRange()
	return self.firstSowableValue, self.lastSowableValue
end

function FieldGroundSystem:getSowingRange()
	return self.firstSowingValue, self.lastSowingValue
end

function FieldGroundSystem:getGroundAngleMaxValue()
	return self.angleMaxValue
end

function FieldGroundSystem:getGroundAngleStep()
	return self.angleStep
end

function FieldGroundSystem:getChopperTypeValue(chopperType)
	return self.fieldChopperTypeValue[chopperType]
end

-- Local values: data
function FieldGroundSystem:getDensityMapData(levelType)
	local v136_ = self.densityMaps[levelType]
	if v136_ == nil then
		return nil
	else
		return v136_.map, v136_.firstChannel, v136_.numChannels
	end
end

-- Local values: data
function FieldGroundSystem:getMaxValue(levelType)
	local v139_ = self.densityMaps[levelType]
	if v139_ == nil then
		return nil
	else
		return v139_.maxValue
	end
end

-- Local values: data
function FieldGroundSystem:getSize(levelType)
	local v142_ = self.densityMaps[levelType]
	if v142_ == nil then
		return nil, nil
	else
		return v142_.width, v142_.height
	end
end

-- Local values: data, value, terrainSize, localX, localZ, densityBits
function FieldGroundSystem:getValueAtWorldPos(levelType, worldPosX, worldPosY, worldPosZ)
	local v147_ = self.densityMaps[levelType]
	if v147_ == nil then
		return nil
	end
	if not v147_.isBitVector then
		local v148_ = getDensityAtWorldPos(v147_.map, worldPosX, 0, worldPosZ)
		local v149_ = v147_.firstChannel
		local v150_ = bit32.rshift(v148_, v149_)
		local v151_ = 2 ^ v147_.numChannels - 1
		return bit32.band(v150_, v151_)
	end
	local v152_ = g_currentMission.terrainSize
	local v153_ = v147_.width * (worldPosX + v152_ * 0.5) / v152_
	local v154_ = math.floor(v153_)
	local v155_ = v147_.height * (worldPosZ + v152_ * 0.5) / v152_
	local v156_ = math.floor(v155_)
	return getBitVectorMapPoint(v147_.map, v154_, v156_, v147_.firstChannel, v147_.numChannels)
end

function FieldGroundSystem:getDisplacementData()
	return self.displacementId, 0, self.displacementNumChannels
end

function FieldGroundSystem:getDisplacementCustomFlagData()
	return self.displacementCustomFlagId, 0, 1
end

function FieldGroundSystem:getDisplacementResetValue()
	return self.displacementResetValue
end
