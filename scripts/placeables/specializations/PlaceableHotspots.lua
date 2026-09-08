PlaceableHotspots = {}

function PlaceableHotspots.prerequisitesPresent(specializations)
	return true
end

function PlaceableHotspots.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getHotspot", PlaceableHotspots.getHotspot)
	SpecializationUtil.registerFunction(placeableType, "updateHotspots", PlaceableHotspots.updateHotspots)
	SpecializationUtil.registerFunction(placeableType, "setHotspotVisible", PlaceableHotspots.setHotspotVisible)
end

function PlaceableHotspots.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHotspots)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHotspots)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHotspots)
	SpecializationUtil.registerEventListener(placeableType, "onOwnerChanged", PlaceableHotspots)
end

function PlaceableHotspots.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Hotspots")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".hotspots.hotspot(?)#linkNode", "Node where hotspot is linked to")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".hotspots.hotspot(?)#teleportNode", "Node where player is teleported to. Teleporting is only available if this is set")
	schema:register(XMLValueType.STRING, basePath .. ".hotspots.hotspot(?)#type", "Placeable hotspot type", "UNLOADING", false, table.toList(PlaceableHotspot.TYPE))
	schema:register(XMLValueType.VECTOR_2, basePath .. ".hotspots.hotspot(?)#worldPosition", "Placeable world position")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".hotspots.hotspot(?)#teleportWorldPosition", "Placeable teleport world position")
	schema:register(XMLValueType.STRING, basePath .. ".hotspots.hotspot(?)#text", "Placeable hotspot text")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableHotspots:onLoad(savegame)
	local v_u_6_ = self.spec_hotspots
	v_u_6_.mapHotspots = {}
	self.xmlFile:iterate("placeable.hotspots.hotspot", function(_, p7_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v8_ = PlaceableHotspot.new()
		v8_:setPlaceable(self)
		local v9_ = self.xmlFile:getValue(p7_ .. "#type", "UNLOADING")
		local v10_ = PlaceableHotspot.getTypeByName(v9_)
		if v10_ == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown placeable hotspot type \'%s\'. Falling back to type \'UNLOADING\'\nAvailable types: %s", v9_, table.concatKeys(PlaceableHotspot.TYPE, " "))
			v10_ = PlaceableHotspot.TYPE.UNLOADING
		end
		v8_:setPlaceableType(v10_)
		local v11_ = self.xmlFile:getValue(p7_ .. "#linkNode", nil, self.components, self.i3dMappings) or self.rootNode
		if v11_ ~= nil then
			local v12_, _, v13_ = getWorldTranslation(v11_)
			v8_:setWorldPosition(v12_, v13_)
		end
		local v14_ = self.xmlFile:getValue(p7_ .. "#teleportNode", nil, self.components, self.i3dMappings)
		if v14_ ~= nil then
			local v15_, v16_, v17_ = getWorldTranslation(v14_)
			v8_:setTeleportWorldPosition(v15_, v16_, v17_)
		end
		local v18_, v19_ = self.xmlFile:getValue(p7_ .. "#worldPosition", nil)
		if v18_ ~= nil then
			v8_:setWorldPosition(v18_, v19_)
		end
		local v20_, v21_, v22_ = self.xmlFile:getValue(p7_ .. "#teleportWorldPosition", nil)
		if v20_ ~= nil then
			if g_currentMission ~= nil then
				local v23_ = getTerrainHeightAtWorldPos
				local v24_ = g_terrainNode
				v21_ = math.max(v21_, v23_(v24_, v20_, 0, v22_))
			end
			v8_:setTeleportWorldPosition(v20_, v21_, v22_)
		end
		local v25_ = self.xmlFile:getValue(p7_ .. "#text", nil)
		if v25_ ~= nil then
			v8_:setName((g_i18n:convertText(v25_, self.customEnvironment)))
		end
		local v26_ = v_u_6_.mapHotspots
		table.insert(v26_, v8_)
	end)
end

-- Local values: spec, _, hotspot
function PlaceableHotspots:onDelete()
	local v28_ = self.spec_hotspots
	g_messageCenter:unsubscribeAll(self)
	if v28_.mapHotspots ~= nil then
		for _, v29_ in ipairs(v28_.mapHotspots) do
			g_currentMission:removeMapHotspot(v29_)
			v29_:delete()
		end
	end
end

-- Local values: spec, _, hotspot
function PlaceableHotspots:onPostFinalizePlacement()
	local v31_ = self.spec_hotspots
	for _, v32_ in ipairs(v31_.mapHotspots) do
		g_currentMission:addMapHotspot(v32_)
	end
	self:updateHotspots()
end

function PlaceableHotspots:onOwnerChanged()
	self:updateHotspots()
end

-- Local values: spec, _, hotspot, isVisible
function PlaceableHotspots:updateHotspots()
	local v35_ = self.spec_hotspots
	if v35_.mapHotspots ~= nil then
		for _, v36_ in ipairs(v35_.mapHotspots) do
			v36_:setOwnerFarmId(self.ownerFarmId)
			local v37_ = (v35_.hiddenMapHotspots == nil or not v35_.hiddenMapHotspots[v36_]) and true or false
			if v37_ then
				v37_ = self.ownerFarmId ~= AccessHandler.NOBODY
			end
			v36_:setVisible(v37_)
		end
	end
end

-- Local values: spec
function PlaceableHotspots:getHotspot(index)
	return self.spec_hotspots.mapHotspots[index or 1]
end

-- Local values: spec, hotspot
function PlaceableHotspots:setHotspotVisible(index, isVisible)
	local v43_ = self.spec_hotspots
	if v43_.mapHotspots ~= nil then
		local v44_ = v43_.mapHotspots[index]
		if v44_ == nil then
			Logging.warning("Placeable hotspot \'%s\' not defined in \'%s\'", index, self.configFileName)
		else
			if not isVisible then
				if v43_.hiddenMapHotspots == nil then
					v43_.hiddenMapHotspots = {}
				end
				v43_.hiddenMapHotspots[v44_] = true
				return
			end
			if v43_.hiddenMapHotspots ~= nil then
				v43_.hiddenMapHotspots[v44_] = nil
				if next(v43_.hiddenMapHotspots) == nil then
					v43_.hiddenMapHotspots = nil
					return
				end
			end
		end
	end
end
