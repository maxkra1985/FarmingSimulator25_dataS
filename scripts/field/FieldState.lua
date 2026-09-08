-- Local values: FieldState_mt
FieldState = {}
local FieldState_mt = Class(FieldState)

function FieldState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#fruitType", "Name of the fruit type", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#growthState", "Growthstate of the fruit", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#lastGrowthState", "Last growthstate of the fruit", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#weedState", "Weedstate on the field", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#stoneLevel", "Weedstate on the field", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#groundType", "Name of the ground type", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#sprayType", "Name of the spray type", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#sprayLevel", "Spray level of the field", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#limeLevel", "Lime level of the field", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#rollerLevel", "Roller level of the field", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#plowLevel", "Plow level of the field", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#stubbleShredLevel", "Stubble shred level of the field", nil, false)
	schema:register(XMLValueType.INT, basePath .. "#waterLevel", "Water level of the field", nil, false)
end

-- Upvalues: FieldState_mt
-- Local values: self
function FieldState.new(customMt)
	-- upvalues: (copy) FieldState_mt
	local v5_ = customMt or FieldState_mt
	local v6_ = setmetatable({}, v5_)
	v6_.isValid = false
	v6_.fruitTypeIndex = FruitType.UNKNOWN
	v6_.growthState = 0
	v6_.lastGrowthState = 0
	v6_.weedState = 0
	v6_.weedFactor = 0
	v6_.stoneLevel = 0
	v6_.groundType = FieldGroundType.NONE
	v6_.sprayLevel = 0
	v6_.sprayType = 0
	v6_.limeLevel = 0
	v6_.rollerLevel = 0
	v6_.plowLevel = 0
	v6_.stubbleShredLevel = 0
	v6_.waterLevel = 0
	v6_.farmlandId = 0
	v6_.ownerFarmId = AccessHandler.NOBODY
	return v6_
end

-- Local values: fruitName, groundTypeName, sprayTypeName
function FieldState:saveToXMLFile(xmlFile, key)
	if self.isValid then
		local v10_ = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
		local v11_ = FieldGroundType.getName(self.groundType) or "UNKNOWN"
		local v12_ = FieldSprayType.getName(self.sprayType) or "UNKNOWN"
		xmlFile:setString(key .. "#fruitType", v10_ or "UNKNOWN")
		xmlFile:setInt(key .. "#growthState", self.growthState)
		xmlFile:setInt(key .. "#lastGrowthState", self.lastGrowthState)
		xmlFile:setInt(key .. "#weedState", self.weedState)
		xmlFile:setInt(key .. "#stoneLevel", self.stoneLevel)
		xmlFile:setString(key .. "#groundType", v11_)
		xmlFile:setString(key .. "#sprayType", v12_)
		xmlFile:setInt(key .. "#sprayLevel", self.sprayLevel)
		xmlFile:setInt(key .. "#limeLevel", self.limeLevel)
		xmlFile:setInt(key .. "#rollerLevel", self.rollerLevel)
		xmlFile:setInt(key .. "#plowLevel", self.plowLevel)
		xmlFile:setInt(key .. "#stubbleShredLevel", self.stubbleShredLevel)
		xmlFile:setInt(key .. "#waterLevel", self.waterLevel)
	end
end

-- Local values: fruitTypeName, fruitType, groundTypeName, sprayTypeName
function FieldState:loadFromXMLFile(xmlFile, key)
	local v16_ = xmlFile:getString(key .. "#fruitType")
	if v16_ == nil then
		return false
	end
	local v17_ = g_fruitTypeManager:getFruitTypeByName(v16_)
	if v17_ ~= nil then
		self.fruitTypeIndex = v17_.index
		self.growthState = xmlFile:getInt(key .. "#growthState") or self.growthState
		self.lastGrowthState = xmlFile:getInt(key .. "#lastGrowthState") or self.growthState
	end
	self.weedState = xmlFile:getInt(key .. "#weedState") or self.weedState
	self.stoneLevel = xmlFile:getInt(key .. "#stoneLevel") or self.stoneLevel
	local v18_ = xmlFile:getString(key .. "#groundType")
	self.groundType = FieldGroundType.getByName(v18_) or FieldGroundType.NONE
	local v19_ = xmlFile:getString(key .. "#sprayType")
	self.sprayType = FieldSprayType.getByName(v19_) or FieldSprayType.NONE
	self.sprayLevel = xmlFile:getInt(key .. "#sprayLevel") or self.sprayLevel
	self.limeLevel = xmlFile:getInt(key .. "#limeLevel") or self.limeLevel
	self.rollerLevel = xmlFile:getInt(key .. "#rollerLevel") or self.rollerLevel
	self.plowLevel = xmlFile:getInt(key .. "#plowLevel") or self.plowLevel
	self.stubbleShredLevel = xmlFile:getInt(key .. "#stubbleShredLevel") or self.stubbleShredLevel
	self.waterLevel = xmlFile:getInt(key .. "#waterLevel") or self.waterLevel
	self.isValid = true
	return true
end

-- Local values: fieldGroundSystem, dataPlaneId, densityTypeIndex, desc, state, groundTypeValue, sprayTypeValue
function FieldState:update(x, z)
	local v23_ = g_currentMission.fieldGroundSystem
	self.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
	self.ownerFarmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)
	self.lastFruitTypeIndex = self.fruitTypeIndex
	self.lastGrowthState = self.growthState
	self.isValid = true
	self.fruitTypeIndex = FruitType.UNKNOWN
	self.growthState = 0
	local v24_ = g_fruitTypeManager:getDefaultDataPlaneId()
	if v24_ ~= nil then
		local v25_ = getDensityTypeIndexAtWorldPos(v24_, x, 0, z)
		local v26_ = g_fruitTypeManager:getFruitTypeByDensityTypeIndex(v25_)
		if v26_ ~= nil then
			self.fruitTypeIndex = v26_.index
			self.growthState = v26_:getGrowthStateByDensityState((getDensityStatesAtWorldPos(v24_, x, 0, z)))
		end
	end
	if self.fruitTypeIndex ~= self.lastFruitTypeIndex then
		self.lastGrowthState = 0
	end
	self.weedState = g_currentMission.weedSystem:getWeedStateAtWorldPos(x, z)
	self.weedFactor = g_currentMission.weedSystem:getWeedFactorAtWorldPos(x, z)
	self.stoneLevel = g_currentMission.stoneSystem:getStoneLevelAtWorldPos(x, z)
	local v27_ = v23_:getValueAtWorldPos(FieldDensityMap.GROUND_TYPE, x, 0, z)
	self.groundType = FieldGroundType.getTypeByValue(v27_)
	local v28_ = v23_:getValueAtWorldPos(FieldDensityMap.SPRAY_TYPE, x, 0, z)
	self.sprayType = FieldSprayType.getTypeByValue(v28_)
	self.sprayLevel = v23_:getValueAtWorldPos(FieldDensityMap.SPRAY_LEVEL, x, 0, z)
	self.limeLevel = v23_:getValueAtWorldPos(FieldDensityMap.LIME_LEVEL, x, 0, z)
	self.rollerLevel = v23_:getValueAtWorldPos(FieldDensityMap.ROLLER_LEVEL, x, 0, z)
	self.plowLevel = v23_:getValueAtWorldPos(FieldDensityMap.PLOW_LEVEL, x, 0, z)
	self.stubbleShredLevel = v23_:getValueAtWorldPos(FieldDensityMap.STUBBLE_SHRED_LEVEL, x, 0, z)
	self.waterLevel = v23_:getValueAtWorldPos(FieldDensityMap.WATER_LEVEL, x, 0, z)
end

-- Local values: fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, harvestMultiplier
function FieldState:getHarvestScaleMultiplier()
	local v30_ = self.fruitTypeIndex
	local v31_, v32_, v33_, v34_, v35_, v36_ = self:getHarvestScaleFactors()
	return g_currentMission:getHarvestScaleMultiplier(v30_, v31_, v32_, v33_, v34_, v35_, v36_, 0)
end

-- Local values: missionInfo, fieldGroundSystem, sprayLevelMax, plowLevelMax, limeLevelMax, rollerLevelMax, plowFactor, limeFactor, rollerFactor, sprayFactor, weedFactor, stubbleFactor
function FieldState:getHarvestScaleFactors()
	local v38_ = g_currentMission.missionInfo
	local v39_ = g_currentMission.fieldGroundSystem
	local v40_ = v39_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	local v41_ = v39_:getMaxValue(FieldDensityMap.PLOW_LEVEL)
	local v42_ = v39_:getMaxValue(FieldDensityMap.LIME_LEVEL)
	local v43_ = v39_:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
	local v44_ = not v38_.plowingRequiredEnabled and 1 or self.plowLevel / v41_
	local v45_ = not (Platform.gameplay.useLimeCounter and v38_.limeRequired) and 1 or self.limeLevel / v42_
	local v46_ = not Platform.gameplay.useRolling and 1 or 1 - self.rollerLevel / v43_
	return self.sprayLevel / v40_, v44_, v45_, not v38_.weedsEnabled and 1 or 1 - self.weedFactor, not Platform.gameplay.useStubbleShred and 1 or self.stubbleShredLevel, v46_
end

-- Local values: fieldUpdateTask
function FieldState:createFieldUpdateTask()
	local v48_ = FieldUpdateTask.new()
	v48_:setFruit(self.fruitTypeIndex, self.growthState)
	v48_:setWeedState(self.weedState)
	v48_:setStoneLevel(self.stoneLevel)
	v48_:setGroundType(self.groundType)
	v48_:setSprayType(self.sprayType)
	v48_:setSprayLevel(self.sprayLevel)
	v48_:setPlowLevel(self.plowLevel)
	v48_:setLimeLevel(self.limeLevel)
	v48_:setRollerLevel(self.rollerLevel)
	v48_:setStubbleShredLevel(self.stubbleShredLevel)
	v48_:setWaterLevel(self.waterLevel)
	return v48_
end

-- Local values: fruitTypeName
function FieldState:drawDebug(x, y)
	local v52_ = renderText
	local v53_ = self.isValid
	v52_(x, y, 0.012, "IsValid: " .. tostring(v53_))
	local v54_ = y - 0.013
	local v55_ = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
	renderText(x, v54_, 0.012, "FruitType: " .. tostring(v55_) .. " (" .. self.growthState .. ")")
	local v56_ = v54_ - 0.013
	renderText(x, v56_, 0.012, "WeedState: " .. self.weedState)
	local v57_ = v56_ - 0.013
	renderText(x, v57_, 0.012, "StoneLevel: " .. self.stoneLevel)
	local v58_ = v57_ - 0.013
	renderText(x, v58_, 0.012, "GroundType: " .. FieldGroundType.getName(self.groundType))
	local v59_ = v58_ - 0.013
	renderText(x, v59_, 0.012, "SprayType: " .. FieldSprayType.getName(self.sprayType))
	local v60_ = v59_ - 0.013
	renderText(x, v60_, 0.012, "SprayLevel: " .. self.sprayLevel)
	local v61_ = v60_ - 0.013
	renderText(x, v61_, 0.012, "LimeLevel: " .. self.limeLevel)
	local v62_ = v61_ - 0.013
	renderText(x, v62_, 0.012, "RollerLevel: " .. self.rollerLevel)
	local v63_ = v62_ - 0.013
	renderText(x, v63_, 0.012, "PlowLevel: " .. self.plowLevel)
	local v64_ = v63_ - 0.013
	renderText(x, v64_, 0.012, "StubbleLevel: " .. self.stubbleShredLevel)
	local v65_ = v64_ - 0.013
	renderText(x, v65_, 0.012, "WaterLevel: " .. self.waterLevel)
	return v65_ - 0.013
end

-- Local values: fruitTypeDesc, fruitTypeName, growthStateName, text, r, g, b, a
function FieldState:drawDebugAtWorldPosition(x, y, z, textSize, textColor)
	local v72_ = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
	local v73_ = "None"
	local v74_
	if v72_ == nil then
		v74_ = "Unknown"
	else
		v74_ = v72_.name
		v73_ = v72_:getGrowthStateName(self.growthState) or v73_
	end
	local v75_ = (((((((((("" .. string.format("FruitType: %s (%d - %s)\n", v74_, self.growthState, v73_)) .. string.format("WeedState: %s\n", self.weedState)) .. string.format("StoneLevel: %s\n", self.stoneLevel)) .. string.format("GroundType: %s\n", FieldGroundType.getName(self.groundType))) .. string.format("SprayType: %s\n", FieldSprayType.getName(self.sprayType))) .. string.format("SprayLevel: %d\n", self.sprayLevel)) .. string.format("LimeLevel: %d\n", self.limeLevel)) .. string.format("PlowLevel: %d\n", self.plowLevel)) .. string.format("RollerLevel: %d\n", self.rollerLevel)) .. string.format("StubbleLevel: %d\n", self.stubbleShredLevel)) .. string.format("WaterLevel: %d\n", self.waterLevel)
	local v76_, v77_, v78_, v79_ = textColor:unpack()
	Utils.renderTextAtWorldPosition(x, y, z, v75_, textSize, 0, v76_, v77_, v78_, v79_)
end
