PlaceableFoliageAreas = {}

function PlaceableFoliageAreas.prerequisitesPresent(specializations)
	return true
end

function PlaceableFoliageAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadFoliageArea", PlaceableFoliageAreas.loadFoliageArea)
end

function PlaceableFoliageAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFoliageAreas)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableFoliageAreas)
end

function PlaceableFoliageAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("FoliageAreas")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foliageAreas.foliageArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foliageAreas.foliageArea(?)#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foliageAreas.foliageArea(?)#heightNode", "Height node")
	schema:register(XMLValueType.STRING, basePath .. ".foliageAreas.foliageArea(?)#fruitType", "Fruit type name")
	schema:register(XMLValueType.STRING, basePath .. ".foliageAreas.foliageArea(?)#growthStateName", "Fruit type growth state name")
	schema:register(XMLValueType.STRING, basePath .. ".foliageAreas.foliageArea(?)#decoFoliage", "Deco foliage name")
	schema:register(XMLValueType.INT, basePath .. ".foliageAreas.foliageArea(?)#state", "Fruit type state")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableFoliageAreas:onLoad(savegame)
	local v_u_6_ = self.spec_foliageAreas
	v_u_6_.areas = {}
	self.xmlFile:iterate("placeable.foliageAreas.foliageArea", function(_, p7_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v8_ = {}
		if self:loadFoliageArea(self.xmlFile, p7_, v8_) then
			local v9_ = v_u_6_.areas
			table.insert(v9_, v8_)
		end
	end)
end

-- Local values: fruitTypeName, decoFoliage, fruitTypeDesc, fruitGrowthState, growthStateName, start, width, height
function PlaceableFoliageAreas:loadFoliageArea(xmlFile, key, area)
	local v14_ = xmlFile:getValue(key .. "#fruitType")
	local v15_ = xmlFile:getValue(key .. "#decoFoliage")
	if v14_ ~= nil and v15_ ~= nil then
		Logging.xmlInfo(xmlFile, "foliage area has both \'fruitType\' and \'decoFoliage\' defined for \'%s\'. Ignoring decoFoliage", key)
		v15_ = nil
	end
	local v16_ = nil
	local v17_
	if v14_ == nil then
		v17_ = nil
	else
		v17_ = g_fruitTypeManager:getFruitTypeByName(v14_)
		if v17_ == nil then
			Logging.xmlWarning(xmlFile, "Foliage area fruit type \'%s\' not defined for \'%s\'", v14_, key)
			return false
		end
		local v18_ = xmlFile:getValue(key .. "#growthStateName")
		if v18_ ~= nil then
			v16_ = v17_:getGrowthStateByName(v18_)
			if v16_ == nil then
				Logging.xmlWarning(xmlFile, "Foliage area fruit type growth state name \'%s\' not defined for \'%s\'", v18_, key)
			end
		end
		if v16_ == nil then
			v16_ = xmlFile:getValue(key .. "#state", v17_.maxHarvestingGrowthState - 1)
		end
	end
	if v15_ ~= nil and not g_currentMission.foliageSystem:getIsDecoLayerDefined(v15_) then
		Logging.xmlInfo(xmlFile, "Foliage area decoFoliage \'%s\' not defined on current map for \'%s\'", v15_, key)
		return false
	end
	local v19_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	if v19_ == nil then
		Logging.xmlWarning(xmlFile, "Foliage area start node not defined for \'%s\'", key)
		return false
	end
	local v20_ = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
	if v20_ == nil then
		Logging.xmlWarning(xmlFile, "Foliage area width node not defined for \'%s\'", key)
		return false
	end
	local v21_ = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
	if v21_ == nil then
		Logging.xmlWarning(xmlFile, "Foliage area height node not defined for \'%s\'", key)
		return false
	end
	area.start = v19_
	area.width = v20_
	area.height = v21_
	area.fruitGrowthState = v16_
	area.fruitTypeDesc = v17_
	area.decoFoliage = v15_
	return true
end

-- Local values: spec, _, area, fieldArea, fieldUpdateTask, x, _, z, xWidth, _, zWidth, xHeight, _, zHeight
function PlaceableFoliageAreas:onPostFinalizePlacement()
	if self.isServer then
		local v23_ = self.spec_foliageAreas
		for _, v24_ in pairs(v23_.areas) do
			if v24_.fruitTypeDesc == nil then
				local v25_, _, v26_ = getWorldTranslation(v24_.start)
				local v27_, _, v28_ = getWorldTranslation(v24_.width)
				local v29_, _, v30_ = getWorldTranslation(v24_.height)
				g_currentMission.foliageSystem:applyDecoFoliage(v24_.decoFoliage, v25_, v26_, v27_, v28_, v29_, v30_)
			else
				local v31_ = DensityMapParallelogram.createFromNodes(v24_.start, v24_.width, v24_.height)
				local v32_ = FieldUpdateTask.new()
				v32_:setArea(v31_)
				v32_:setFruit(v24_.fruitTypeDesc.index, v24_.fruitGrowthState)
				g_fieldManager:addFieldUpdateTask(v32_)
			end
		end
	end
end
