PlaceableClearAreas = {}

function PlaceableClearAreas.prerequisitesPresent(specializations)
	return true
end

function PlaceableClearAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadClearArea", PlaceableClearAreas.loadClearArea)
end

function PlaceableClearAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableClearAreas)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableClearAreas)
end

function PlaceableClearAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ClearAreas")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearAreas.clearArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearAreas.clearArea(?)#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearAreas.clearArea(?)#heightNode", "Height node")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableClearAreas:onLoad(savegame)
	local v_u_6_ = self.spec_clearAreas
	v_u_6_.areas = {}
	self.xmlFile:iterate("placeable.clearAreas.clearArea", function(_, p7_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v8_ = {}
		if self:loadClearArea(self.xmlFile, p7_, v8_) then
			local v9_ = v_u_6_.areas
			table.insert(v9_, v8_)
		end
	end)
	if not self.xmlFile:hasProperty("placeable.clearAreas") then
		Logging.xmlWarning(self.xmlFile, "Missing clear areas")
	end
end

-- Local values: start, width, height
function PlaceableClearAreas:loadClearArea(xmlFile, key, area)
	local v14_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	if v14_ == nil then
		Logging.xmlWarning(xmlFile, "Clear area start node not defined for \'%s\'", key)
		return false
	end
	local v15_ = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
	if v15_ == nil then
		Logging.xmlWarning(xmlFile, "Clear area width node not defined for \'%s\'", key)
		return false
	end
	local v16_ = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
	if v16_ == nil then
		Logging.xmlWarning(xmlFile, "Clear area height node not defined for \'%s\'", key)
		return false
	end
	area.start = v14_
	area.width = v15_
	area.height = v16_
	return true
end

-- Local values: spec, _, area, x, _, z, x1, _, z1, x2, _, z2
function PlaceableClearAreas:onPostFinalizePlacement()
	if self.isServer and not self.isLoadedFromSavegame then
		local v18_ = self.spec_clearAreas
		for _, v19_ in pairs(v18_.areas) do
			local v20_, _, v21_ = getWorldTranslation(v19_.start)
			local v22_, _, v23_ = getWorldTranslation(v19_.width)
			local v24_, _, v25_ = getWorldTranslation(v19_.height)
			FSDensityMapUtil.removeFieldArea(v20_, v21_, v22_, v23_, v24_, v25_, false)
			FSDensityMapUtil.removeWeedArea(v20_, v21_, v22_, v23_, v24_, v25_)
			FSDensityMapUtil.removeStoneArea(v20_, v21_, v22_, v23_, v24_, v25_)
			FSDensityMapUtil.eraseTireTrack(v20_, v21_, v22_, v23_, v24_, v25_)
			FSDensityMapUtil.clearDecoArea(v20_, v21_, v22_, v23_, v24_, v25_)
			DensityMapHeightUtil.clearArea(v20_, v21_, v22_, v23_, v24_, v25_)
		end
	end
end
