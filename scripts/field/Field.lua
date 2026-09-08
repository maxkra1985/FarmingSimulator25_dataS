-- Local values: Field_mt
Field = {}
Field.DEPRECATED_USER_ATTRIBUTES = {}
Field.DEPRECATED_USER_ATTRIBUTES.fieldMissionAllowed = "missionAllowed"
Field.DEPRECATED_USER_ATTRIBUTES.fieldGrassMission = "missionOnlyGrass"
Field.DEPRECATED_USER_ATTRIBUTES.fieldDimensionIndex = "dimensionIndex"
Field.DEPRECATED_USER_ATTRIBUTES.fieldAngle = "angle"
local Field_mt = Class(Field)

function Field.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#plannedFruit", "Name of the planned fruit type", nil, false)
	FieldState.registerXMLPaths(schema, basePath)
end

-- Upvalues: Field_mt
-- Local values: self
function Field.new(customMt)
	-- upvalues: (copy) Field_mt
	local v5_ = customMt or Field_mt
	local v6_ = setmetatable({}, v5_)
	v6_.name = nil
	v6_.rootNode = nil
	v6_.densityMapPolygon = DensityMapPolygon.new()
	v6_.polygonPoints = {}
	v6_.angle = 0
	v6_.areaHa = 1
	v6_.farmland = nil
	v6_.currentMission = nil
	v6_.plannedFruitTypeIndex = FruitType.UNKNOWN
	v6_.isMissionAllowed = true
	v6_.grassMissionOnly = false
	v6_.posX = 0
	v6_.posZ = 0
	v6_.fieldState = FieldState.new()
	return v6_
end

-- Local values: name, oldAttribute, newAttribute, polygonIndex, polygonPointsRoot, i, polygonPoint, sqm, angle, angleRad
function Field:load(id)
	self.rootNode = id
	local v9_ = getUserAttribute(id, "name")
	if not string.isNilOrWhitespace(v9_) then
		self.name = g_i18n:convertText(v9_, g_currentMission.loadingMapModName)
	end
	for v10_, v11_ in pairs(Field.DEPRECATED_USER_ATTRIBUTES) do
		if getUserAttribute(id, v10_) ~= nil then
			Logging.warning("User attribute \'%s\' is not supported anymore for field \'%s\'. Please use \'%s\' instead!", v10_, getName(id), v11_)
		end
	end
	local v12_ = getUserAttribute(id, "polygonIndex")
	if v12_ == nil then
		Logging.warning("No polygonIndex defined for field \'%s\'!", getName(id))
		return false
	end
	local v13_ = I3DUtil.indexToObject(id, v12_)
	if v13_ == nil then
		Logging.warning("Could not resolve polygonIndex \'%s\' for field \'%s\'!", v12_, getName(id))
		return false
	end
	for v14_ = 0, getNumOfChildren(v13_) - 1 do
		local v15_ = getChildAt(v13_, v14_)
		local v16_ = self.polygonPoints
		table.insert(v16_, v15_)
	end
	self.densityMapPolygon:updateFromNodes(self.polygonPoints)
	self.areaHa = MathUtil.getPolygon2DSize(self.polygonPoints) / 10000
	local v17_, v18_ = MathUtil.getPolygonLabel(self.polygonPoints, 1)
	self.posX = v17_
	self.posZ = v18_
	self.nameIndicator = I3DUtil.indexToObject(id, getUserAttribute(id, "nameIndicatorIndex"))
	self.teleportNode = I3DUtil.indexToObject(id, getUserAttribute(id, "teleportIndicatorIndex"))
	local v19_ = getUserAttribute(id, "angle") or 0
	local v20_ = math.rad(v19_)
	self.angle = FSDensityMapUtil.convertToDensityMapAngle(v20_, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	self.isMissionAllowed = Utils.getNoNil(getUserAttribute(id, "missionAllowed"), true)
	self.grassMissionOnly = Utils.getNoNil(getUserAttribute(id, "missionOnlyGrass"), false)
	return true
end

function Field:delete()
	g_messageCenter:unsubscribeAll(self)
end

function Field:saveToXMLFile(xmlFile, key)
	if self.plannedFruitTypeIndex == FruitType.UNKNOWN then
		xmlFile:setString(key .. "#plannedFruit", "FALLOW")
	else
		xmlFile:setString(key .. "#plannedFruit", g_fruitTypeManager:getFruitTypeNameByIndex(self.plannedFruitTypeIndex))
	end
	self.fieldState:saveToXMLFile(xmlFile, key)
end

-- Local values: plannedFruitName, plannedFruitDesc
function Field:loadFromXMLFile(xmlFile, key)
	local v28_ = xmlFile:getString(key .. "#plannedFruit")
	local v29_ = g_fruitTypeManager:getFruitTypeByName(v28_)
	if v28_ == "FALLOW" then
		self.plannedFruitTypeIndex = FruitType.UNKNOWN
	elseif v29_ ~= nil then
		self.plannedFruitTypeIndex = v29_.index
	end
	self.fieldState:loadFromXMLFile(xmlFile, key)
end

function Field:getCenterOfFieldWorldPosition()
	return self.posX, self.posZ
end

-- Local values: x, _, z
function Field:getIndicatorPosition()
	if self.nameIndicator == nil then
		return self.posX, self.posZ
	end
	local v32_, _, v33_ = getWorldTranslation(self.nameIndicator)
	return v32_, v33_
end

-- Local values: x, _, z
function Field:getTeleportPosition()
	if self.teleportNode == nil then
		return self.posX, self.posZ
	end
	local v35_, _, v36_ = getWorldTranslation(self.teleportNode)
	return v35_, v36_
end

function Field:setFarmland(farmland)
	self.farmland = farmland
end

function Field:getFarmland()
	return self.farmland
end

function Field:getId()
	if self.farmland == nil then
		return nil
	else
		return self.farmland:getId()
	end
end

function Field:getName()
	if self.farmland == nil then
		if self.name == nil then
			return tostring(self:getId())
		else
			return self.name
		end
	else
		return self.farmland:getName()
	end
end

function Field:getAngle()
	return self.angle
end

function Field:getAreaHa()
	return self.areaHa
end

function Field:getTeleportNode()
	return self.teleportNode
end

-- Local values: farmId
function Field:getHasOwner()
	local v46_ = FarmlandManager.NO_OWNER_FARM_ID
	if self.farmland ~= nil then
		v46_ = g_farmlandManager:getFarmlandOwner(self.farmland:getId())
	end
	return v46_ ~= FarmlandManager.NO_OWNER_FARM_ID
end

-- Local values: farmId
function Field:getOwner()
	local v48_ = FarmlandManager.NO_OWNER_FARM_ID
	if self.farmland ~= nil then
		v48_ = g_farmlandManager:getFarmlandOwner(self.farmland:getId())
	end
	return v48_
end

-- Local values: state, fieldUpdateTask
function Field:reset(immediate)
	if self.fieldState.isValid then
		local v51_ = self.fieldState:createFieldUpdateTask()
		v51_:clearHeight()
		v51_:setArea(self:getDensityMapPolygon())
		Logging.devInfo("Field:reset - Added task to reset field \'%s\'", self:getName())
		g_fieldManager:addFieldUpdateTask(v51_, immediate)
	end
end

function Field:getPolygonPoints()
	return self.polygonPoints
end

function Field:getDensityMapPolygon()
	return self.densityMapPolygon
end

function Field:getPlannedFruitTypeIndex()
	return self.plannedFruitTypeIndex
end

function Field:getFieldState()
	return self.fieldState
end

function Field:getIsReadyForMission()
	if self:getId() == nil then
		return false
	elseif self.isMissionAllowed then
		if self.currentMission == nil then
			return not self:getHasOwner()
		else
			return false
		end
	else
		return false
	end
end

function Field:setMission(mission)
	self.currentMission = mission
end

function Field:updateState()
	if self.currentMission == nil or not self.currentMission:getIsRunning() then
		Logging.devInfo("Field:updateState - Updating state for field \'%s\'", self:getName())
		self.fieldState:update(self.posX, self.posZ)
	end
end

-- Local values: plannedFruitTypeName
function Field:drawDebug(x, y)
	renderText(x, y, 0.02, "Field: " .. self:getName())
	local v63_ = y - 0.013
	if self.currentMission ~= nil then
		setTextColor(0, 1, 0, 1)
	end
	local v64_ = renderText
	local v65_ = self.currentMission ~= nil
	v64_(x, v63_, 0.012, "Mission: " .. tostring(v65_))
	setTextColor(1, 1, 1, 1)
	local v66_ = v63_ - 0.013
	local v67_ = g_fruitTypeManager:getFruitTypeNameByIndex(self.plannedFruitTypeIndex)
	renderText(x, v66_, 0.012, "Planned: " .. tostring(v67_))
	local v68_ = v66_ - 0.013
	self.fieldState:drawDebug(x, v68_)
	return v68_
end
