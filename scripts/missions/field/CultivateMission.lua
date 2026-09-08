-- Local values: CultivateMission_mt
CultivateMission = {}
CultivateMission.NAME = "cultivateMission"
local CultivateMission_mt = Class(CultivateMission, AbstractFieldMission)
InitStaticObjectClass(CultivateMission, "CultivateMission")

function CultivateMission.registerXMLPaths(schema, key)
	CultivateMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end

-- Upvalues: CultivateMission_mt
-- Local values: title, description, self
function CultivateMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) CultivateMission_mt
	local v7_ = g_i18n:getText("contract_field_cultivate_title")
	local v8_ = g_i18n:getText("contract_field_cultivate_description")
	local v9_ = AbstractFieldMission.new(isServer, isClient, v7_, v8_, customMt or CultivateMission_mt)
	v9_.workAreaTypes = {
		[WorkAreaType.CULTIVATOR] = true
	}
	return v9_
end

-- Local values: mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, stubbleTillageValue, seedbedValue
function CultivateMission:createModifier()
	local v11_, v12_, v13_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local v14_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
	local v15_ = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
	self.completionModifier = DensityMapModifier.new(v11_, v12_, v13_, g_terrainNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	self.completionFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v14_, v15_)
end

-- Local values: fieldState
function CultivateMission:getFieldFinishTask()
	local v17_ = self.field:getFieldState()
	v17_.fruitTypeIndex = FruitType.UNKNOWN
	v17_.groundType = FieldGroundType.CULTIVATED
	return CultivateMission:superClass().getFieldFinishTask(self)
end

-- Local values: data
function CultivateMission:getRewardPerHa()
	return g_missionManager:getMissionTypeDataByName(CultivateMission.NAME).rewardPerHa
end

function CultivateMission:getMissionTypeName()
	return CultivateMission.NAME
end

function CultivateMission:validate(event)
	if CultivateMission:superClass().validate(self, event) then
		return (self:getIsFinished() or CultivateMission.isAvailableForField(self.field, self)) and true or false
	else
		return false
	end
end

-- Local values: data
function CultivateMission.loadMapData(xmlFile, key, baseDirectory)
	g_missionManager:getMissionTypeDataByName(CultivateMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2300)
	return true
end
function CultivateMission.tryGenerateMission()
	if CultivateMission.canRun() then
		local v22_ = g_fieldManager:getFieldForMission()
		if v22_ == nil then
			return
		end
		if v22_.currentMission ~= nil then
			return
		end
		if not CultivateMission.isAvailableForField(v22_, nil) then
			return
		end
		local v23_ = CultivateMission.new(true, g_client ~= nil)
		if v23_:init(v22_) then
			v23_:setDefaultEndDate()
			return v23_
		end
		v23_:delete()
	end
	return nil
end

-- Local values: fieldState, fruitTypeIndex, growthState, fruitTypeDesc
function CultivateMission.isAvailableForField(field, mission)
	if mission == nil then
		local v26_ = field:getFieldState()
		if not v26_.isValid then
			return false
		end
		if field.grassMissionOnly then
			return false
		end
		local v27_ = v26_.fruitTypeIndex
		if v27_ == FruitType.UNKNOWN then
			return false
		end
		local v28_ = v26_.growthState
		local v29_ = g_fruitTypeManager:getFruitTypeByIndex(v27_)
		if v29_:getIsCatchCrop() and v28_ <= 1 then
			return false
		end
		if not (v29_:getIsCut(v28_) or v29_:getIsWithered(v28_)) then
			return false
		end
	end
	return true
end
function CultivateMission.canRun()
	local v30_ = g_missionManager:getMissionTypeDataByName(CultivateMission.NAME)
	return v30_.numInstances < v30_.maxNumInstances
end
g_missionManager:registerMissionType(CultivateMission, CultivateMission.NAME, 3)
