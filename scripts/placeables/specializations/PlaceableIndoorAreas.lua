PlaceableIndoorAreas = {}

function PlaceableIndoorAreas.prerequisitesPresent(specializations)
	return true
end

function PlaceableIndoorAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadIndoorArea", PlaceableIndoorAreas.loadIndoorArea)
end

function PlaceableIndoorAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableIndoorAreas)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableIndoorAreas)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableIndoorAreas)
end

function PlaceableIndoorAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("IndoorAreas")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".indoorAreas.indoorArea(?)#startNode", "Start node of indoor mask area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".indoorAreas.indoorArea(?)#widthNode", "Width node of indoor mask area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".indoorAreas.indoorArea(?)#heightNode", "Height node of indoor mask area")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableIndoorAreas:onLoad(savegame)
	local v_u_6_ = self.spec_indoorAreas
	v_u_6_.resetIndoorMaskOnDelete = false
	v_u_6_.areas = {}
	self.xmlFile:iterate("placeable.indoorAreas.indoorArea", function(_, p7_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v8_ = {}
		if self:loadIndoorArea(self.xmlFile, p7_, v8_) then
			local v9_ = v_u_6_.areas
			table.insert(v9_, v8_)
		end
	end)
	if not self.xmlFile:hasProperty("placeable.indoorAreas") then
		Logging.xmlWarning(self.xmlFile, "Missing indoor areas")
	end
end

-- Local values: spec, _, area
function PlaceableIndoorAreas:onDelete()
	local v11_ = self.spec_indoorAreas
	if v11_.areas ~= nil and (v11_.resetIndoorMaskOnDelete and not self.isReloading) then
		for _, v12_ in ipairs(v11_.areas) do
			g_currentMission.indoorMask:setStateByArea(v12_, IndoorMask.OUTDOOR)
		end
	end
end

-- Local values: start, width, height
function PlaceableIndoorAreas:loadIndoorArea(xmlFile, key, area)
	local v17_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	if v17_ == nil then
		Logging.xmlWarning(xmlFile, "Indoor area start node not defined for \'%s\'", key)
		return false
	end
	local v18_ = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
	if v18_ == nil then
		Logging.xmlWarning(xmlFile, "Indoor area width node not defined for \'%s\'", key)
		return false
	end
	local v19_ = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
	if v19_ == nil then
		Logging.xmlWarning(xmlFile, "Indoor area height node not defined for \'%s\'", key)
		return false
	end
	area.start = v17_
	area.width = v18_
	area.height = v19_
	return true
end

-- Local values: spec, _, area
function PlaceableIndoorAreas:onFinalizePlacement()
	local v21_ = self.spec_indoorAreas
	for _, v22_ in pairs(v21_.areas) do
		g_currentMission.indoorMask:setStateByArea(v22_, IndoorMask.INDOOR)
	end
	v21_.resetIndoorMaskOnDelete = true
end
