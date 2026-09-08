PlaceableLeveling = {}

function PlaceableLeveling.prerequisitesPresent(specializations)
	return true
end

function PlaceableLeveling.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadLevelArea", PlaceableLeveling.loadLevelArea)
	SpecializationUtil.registerFunction(placeableType, "loadPaintArea", PlaceableLeveling.loadPaintArea)
	SpecializationUtil.registerFunction(placeableType, "addDeformationArea", PlaceableLeveling.addDeformationArea)
	SpecializationUtil.registerFunction(placeableType, "applyDeformation", PlaceableLeveling.applyDeformation)
	SpecializationUtil.registerFunction(placeableType, "getDeformationObjects", PlaceableLeveling.getDeformationObjects)
	SpecializationUtil.registerFunction(placeableType, "getRequiresLeveling", PlaceableLeveling.getRequiresLeveling)
	SpecializationUtil.registerFunction(placeableType, "getRequiresRealignAfterLeveling", PlaceableLeveling.getRequiresRealignAfterLeveling)
end

function PlaceableLeveling.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableLeveling)
end

function PlaceableLeveling.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Leveling")
	schema:register(XMLValueType.BOOL, basePath .. ".leveling#requireLeveling", "If true, the ground around the placeable is leveled and all other leveling properties are used", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".leveling#maxSmoothDistance", "Radius around leveling areas where terrain will be smoothed towards the placeable", 3)
	schema:register(XMLValueType.ANGLE, basePath .. ".leveling#maxSlope", "Maximum slope of terrain created by outside smoothing expressed as an angle in degrees", 45)
	schema:register(XMLValueType.ANGLE, basePath .. ".leveling#maxEdgeAngle", "Maximum angle between polygons in smoothed areas expressed as an angle in degrees", 45)
	schema:register(XMLValueType.STRING, basePath .. ".leveling#smoothingGroundType", "Ground type used to paint the smoothed ground from leveling areas up to the radius of \'maxSmoothDistance\'  (one of the ground types defined in groundTypes.xml)")
	schema:register(XMLValueType.BOOL, basePath .. ".leveling#realignAfterLeveling", "If false placeable will not be realigned in y after leveling was performed", true)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.levelAreas.levelArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.levelAreas.levelArea(?)#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.levelAreas.levelArea(?)#heightNode", "Height node")
	schema:register(XMLValueType.STRING, basePath .. ".leveling.levelAreas.levelArea(?)#groundType", "Ground type name (one of the ground types defined in groundTypes.xml)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.paintAreas.paintArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.paintAreas.paintArea(?)#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".leveling.paintAreas.paintArea(?)#heightNode", "Height node")
	schema:register(XMLValueType.STRING, basePath .. ".leveling.paintAreas.paintArea(?)#groundType", "Ground type name (one of the ground types defined in groundTypes.xml)")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, smoothingDistance, clampedSmoothingDistance
function PlaceableLeveling:onLoad(savegame)
	local v_u_6_ = self.spec_leveling
	local v_u_7_ = self.xmlFile
	v_u_6_.requiresLeveling = v_u_7_:getValue("placeable.leveling#requireLeveling", false)
	local v8_ = v_u_7_:getValue("placeable.leveling#maxSmoothDistance", 3)
	local v9_ = math.clamp(v8_, 0, 10)
	if v9_ ~= v8_ then
		Logging.xmlWarning(v_u_7_, "Reduced \'placeable.leveling#maxSmoothDistance\' to maximum allowed value of %d", v9_)
	end
	v_u_6_.maxSmoothDistance = v9_
	v_u_6_.maxSlope = v_u_7_:getValue("placeable.leveling#maxSlope", 45)
	v_u_6_.maxEdgeAngle = v_u_7_:getValue("placeable.leveling#maxEdgeAngle", 45)
	v_u_6_.smoothingGroundType = v_u_7_:getValue("placeable.leveling#smoothingGroundType")
	v_u_6_.realignAfterLeveling = v_u_7_:getValue("placeable.leveling#realignAfterLeveling", true)
	if not self.xmlFile:hasProperty("placeable.leveling") then
		Logging.xmlWarning(self.xmlFile, "Missing leveling areas")
	end
	v_u_6_.levelAreas = {}
	v_u_7_:iterate("placeable.leveling.levelAreas.levelArea", function(_, p10_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v11_ = {}
		if self:loadLevelArea(v_u_7_, p10_, v11_) then
			local v12_ = v_u_6_.levelAreas
			table.insert(v12_, v11_)
		end
	end)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.leveling.rampAreas.rampArea", "placeable.leveling.levelAreas.levelArea")
	v_u_6_.paintAreas = {}
	v_u_7_:iterate("placeable.leveling.paintAreas.paintArea", function(_, p13_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v14_ = {}
		if self:loadPaintArea(v_u_7_, p13_, v14_) then
			local v15_ = v_u_6_.paintAreas
			table.insert(v15_, v14_)
		end
	end)
end

-- Local values: start, width, height
function PlaceableLeveling:loadLevelArea(xmlFile, key, area)
	local v20_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	if v20_ == nil then
		Logging.xmlWarning(xmlFile, "Leveling area start node not defined for \'%s\'", key)
		return false
	end
	local v21_ = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
	if v21_ == nil then
		Logging.xmlWarning(xmlFile, "Leveling area width node not defined for \'%s\'", key)
		return false
	end
	local v22_ = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
	if v22_ == nil then
		Logging.xmlWarning(xmlFile, "Leveling area height node not defined for \'%s\'", key)
		return false
	end
	area.start = v20_
	area.width = v21_
	area.height = v22_
	area.groundType = xmlFile:getValue(key .. "#groundType")
	return true
end

-- Local values: start, width, height
function PlaceableLeveling:loadPaintArea(xmlFile, key, area)
	local v27_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	if v27_ == nil then
		Logging.xmlWarning(xmlFile, "Paint area start node not defined for \'%s\'", key)
		return false
	end
	local v28_ = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
	if v28_ == nil then
		Logging.xmlWarning(xmlFile, "Paint area width node not defined for \'%s\'", key)
		return false
	end
	local v29_ = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
	if v29_ == nil then
		Logging.xmlWarning(xmlFile, "Paint area height node not defined for \'%s\'", key)
		return false
	end
	area.start = v27_
	area.width = v28_
	area.height = v29_
	area.groundType = xmlFile:getValue(key .. "#groundType")
	return true
end

-- Local values: spec, deformationObjects, deformationObject, _, levelArea, layer, paintingObject, _, paintArea, layer
function PlaceableLeveling:getDeformationObjects(terrainRootNode, forBlockingOnly, isBlocking)
	local v33_ = self.spec_leveling
	local v34_ = {}
	if terrainRootNode ~= nil and (terrainRootNode ~= 0 and #v33_.levelAreas > 0) then
		local v35_ = TerrainDeformation.new(terrainRootNode)
		if g_densityMapHeightManager.placementCollisionMap ~= nil then
			v35_:setBlockedAreaMap(g_densityMapHeightManager.placementCollisionMap, 0)
		end
		for _, v36_ in pairs(v33_.levelAreas) do
			self:addDeformationArea(v35_, v36_, v36_.groundType == nil and -1 or g_groundTypeManager:getTerrainLayerByType(v36_.groundType), true)
		end
		if v33_.smoothingGroundType ~= nil then
			v35_:setOutsideAreaBrush(g_groundTypeManager:getTerrainLayerByType(v33_.smoothingGroundType))
		end
		v35_:setOutsideAreaConstraints(v33_.maxSmoothDistance, v33_.maxSlope, v33_.maxEdgeAngle)
		v35_:setBlockedAreaMaxDisplacement(0.1)
		v35_:setDynamicObjectCollisionMask(CollisionMask.LEVELING)
		v35_:setDynamicObjectMaxDisplacement(0.3)
		table.insert(v34_, v35_)
	end
	if not forBlockingOnly and #v33_.paintAreas > 0 then
		local v37_ = TerrainDeformation.new(terrainRootNode)
		for _, v38_ in pairs(v33_.paintAreas) do
			self:addDeformationArea(v37_, v38_, v38_.groundType == nil and -1 or g_groundTypeManager:getTerrainLayerByType(v38_.groundType), true)
		end
		v37_:enablePaintingMode()
		table.insert(v34_, v37_)
	end
	return v34_
end

-- Local values: worldStartX, worldStartY, worldStartZ, worldSide1X, worldSide1Y, worldSide1Z, worldSide2X, worldSide2Y, worldSide2Z, side1X, side1Y, side1Z, side2X, side2Y, side2Z
function PlaceableLeveling:addDeformationArea(deformationObject, area, terrainBrushId, writeBlockedAreaMap)
	local v43_, v44_, v45_ = getWorldTranslation(area.start)
	local v46_, v47_, v48_ = getWorldTranslation(area.width)
	local v49_, v50_, v51_ = getWorldTranslation(area.height)
	deformationObject:addArea(v43_, v44_, v45_, v46_ - v43_, v47_ - v44_, v48_ - v45_, v49_ - v43_, v50_ - v44_, v51_ - v45_, terrainBrushId, writeBlockedAreaMap)
end

function PlaceableLeveling:getRequiresLeveling()
	return self.spec_leveling.requiresLeveling
end

function PlaceableLeveling:getRequiresRealignAfterLeveling()
	return self.spec_leveling.realignAfterLeveling
end

-- Local values: deformationObjects, recursiveCallback
function PlaceableLeveling:applyDeformation(isPreview, callback)
	local v57_ = self:getDeformationObjects(g_terrainNode)
	if #v57_ == 0 then
		callback(TerrainDeformation.STATE_SUCCESS, 0, nil)
	else
		g_terrainDeformationQueue:queueJob(v57_[1], isPreview, "callback", {
			["index"] = 1,
			["volume"] = 0,
			["deformationObjects"] = v57_,
			["finishCallback"] = callback,
			["callback"] = function(p58_, p59_, p60_, p61_)
				-- upvalues: (copy) isPreview
				if p59_ == TerrainDeformation.STATE_SUCCESS then
					p58_.volume = p58_.volume + p60_
					p58_.index = p58_.index + 1
					local v62_ = p58_.deformationObjects[p58_.index]
					if v62_ == nil then
						local v_u_63_ = {}
						for _, v64_ in ipairs(p58_.deformationObjects) do
							table.insert(v_u_63_, v64_)
						end
						g_asyncTaskManager:addTask(function()
							-- upvalues: (copy) v_u_63_
							for _, v65_ in ipairs(v_u_63_) do
								v65_:delete()
							end
						end)
						p58_.finishCallback(TerrainDeformation.STATE_SUCCESS, p58_.volume, nil)
					else
						g_terrainDeformationQueue:queueJob(v62_, isPreview, "callback", p58_)
					end
				else
					local v_u_66_ = {}
					for _, v67_ in ipairs(p58_.deformationObjects) do
						table.insert(v_u_66_, v67_)
					end
					g_asyncTaskManager:addTask(function()
						-- upvalues: (copy) v_u_66_
						for _, v68_ in ipairs(v_u_66_) do
							v68_:delete()
						end
					end)
					p58_.finishCallback(p59_, p58_.volume, p61_)
					return
				end
			end
		})
	end
end
