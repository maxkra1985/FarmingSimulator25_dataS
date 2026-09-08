-- Local values: TreeMarkerSystem_mt
TreeMarkerSystem = {}
TreeMarkerSystem.MOD_DIRECTORY = g_currentModDirectory
g_xmlManager:addCreateSchemaFunction(function()
	TreeMarkerSystem.xmlSchema = XMLSchema.new("treeMarkerSystem")
	TreeMarkerSystem.xmlSchemaSavegame = XMLSchema.new("treeMarkerSystem_savegame")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v1_ = TreeMarkerSystem.xmlSchema
	v1_:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?)#name", "Name of the treemarker")
	v1_:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?)#title", "Title of the treemarker")
	v1_:register(XMLValueType.FLOAT, "treeMarkerTypes.treeMarkerType(?)#scale", "Scale of the marker")
	v1_:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?).texture#filename", "Filename of the custom shader texture")
	v1_:register(XMLValueType.STRING, "treeMarkerTypes.treeMarkerType(?).icon#filename", "Filename of the hud icon")
	local v2_ = TreeMarkerSystem.xmlSchemaSavegame
	v2_:register(XMLValueType.STRING, "treeMarkerSystem.treeMarkers.treeMarker(?)#type", "Treemarker type name")
	v2_:register(XMLValueType.BOOL, "treeMarkerSystem.treeMarkers.treeMarker(?)#isSplitShape", "Is treemarker on a splitshape or on a preplaced tree")
	v2_:register(XMLValueType.VECTOR_4, "treeMarkerSystem.treeMarkers.treeMarker(?)#color", "Treemarker color")
	v2_:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#scale", "Treemarker scale")
	v2_:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#posX", "Treemarker x position")
	v2_:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#posY", "Treemarker y position")
	v2_:register(XMLValueType.FLOAT, "treeMarkerSystem.treeMarkers.treeMarker(?)#rotY", "Treemarker rotation")
	v2_:register(XMLValueType.INT, "treeMarkerSystem.treeMarkers.treeMarker(?)#splitShapePart1", "Treemarker splitShapePart1")
	v2_:register(XMLValueType.INT, "treeMarkerSystem.treeMarkers.treeMarker(?)#splitShapePart2", "Treemarker splitShapePart2")
	v2_:register(XMLValueType.INT, "treeMarkerSystem.treeMarkers.treeMarker(?)#splitShapePart3", "Treemarker splitShapePart3")
end)
local TreeMarkerSystem_mt = Class(TreeMarkerSystem)

-- Upvalues: TreeMarkerSystem_mt
-- Local values: self
function TreeMarkerSystem.new(isServer, customMt)
	-- upvalues: (copy) TreeMarkerSystem_mt
	local v6_ = customMt or TreeMarkerSystem_mt
	local v7_ = setmetatable({}, v6_)
	v7_.isServer = isServer
	v7_.treeMarkers = {}
	v7_.nameToTreeMarkerType = {}
	v7_.treeMarkerTypes = {}
	v7_.shaderParameter = "markerPosScaleRot"
	v7_.shaderParameterColor = "markerColorScale"
	v7_.shaderParameterMap = "mMarker"
	return v7_
end

-- Local values: _, treeMarker
function TreeMarkerSystem:delete()
	for _, v9_ in ipairs(self.treeMarkerTypes) do
		delete(v9_.markerTexture)
	end
end

-- Local values: filename
function TreeMarkerSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory
	self:loadTreeMarkerTypes("data/maps/maps_treeMarkerTypes.xml")
	local v13_ = getXMLString(xmlFile, "map.treeMarkerTypes#filename")
	if v13_ ~= nil then
		self:loadTreeMarkerTypes((Utils.getFilename(v13_, baseDirectory)))
	end
	return true
end

-- Local values: _, treeMarker
function TreeMarkerSystem:unloadMapData()
	for _, v15_ in ipairs(self.treeMarkerTypes) do
		delete(v15_.markerTexture)
	end
end

function TreeMarkerSystem:initTerrain()
	self.yWorldPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.01)
	self.xzWorldPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(g_currentMission.terrainSize + 500, 0.5 * (g_currentMission.terrainSize + 500), 0.01)
	self.xTreePosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(10, 0, 0.01)
	self.yTreePosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(50, 0, 0.01)
end

-- Local values: xmlFile, modName, baseDirectory, customEnv, _, key, name, title, scale, textureFilename, iconFilename
function TreeMarkerSystem:loadTreeMarkerTypes(filename)
	local v19_ = XMLFile.loadIfExists("treeMarker", filename, TreeMarkerSystem.xmlSchema)
	if v19_ ~= nil then
		local v20_, v21_ = Utils.getModNameAndBaseDirectory(filename)
		for _, v22_ in v19_:iterator("treeMarkerTypes.treeMarkerType") do
			local v23_ = v19_:getValue(v22_ .. "#name")
			local v24_ = v19_:getValue(v22_ .. "#title")
			local v25_ = v19_:getValue(v22_ .. "#scale")
			local v26_ = v19_:getValue(v22_ .. ".texture#filename")
			local v27_ = v19_:getValue(v22_ .. ".icon#filename")
			if v23_ ~= nil then
				local v28_ = Utils.getFilename(v26_, v21_)
				local v29_ = Utils.getFilename(v27_, v21_)
				self:registerTreeMarkerType(v23_, g_i18n:convertText(v24_, v20_), v25_, v28_, v29_)
			end
		end
		v19_:delete()
	end
end

-- Local values: treeMarkerType, markerTexture
function TreeMarkerSystem:registerTreeMarkerType(name, title, scale, markerFilename, iconFilename)
	if ClassUtil.getIsValidIndexName(name) then
		local v36_ = string.upper(name)
		local v37_ = self.nameToTreeMarkerType[v36_]
		if v37_ == nil then
			v37_ = {}
			self.nameToTreeMarkerType[v36_] = v37_
			local v38_ = self.treeMarkerTypes
			table.insert(v38_, v37_)
			v37_.index = #self.treeMarkerTypes
		end
		v37_.name = v36_
		v37_.title = title or (v37_.title or "Unknown")
		v37_.scale = scale or (v37_.scale or 0.4)
		v37_.iconFilename = iconFilename
		if markerFilename ~= nil then
			local v39_ = createMaterialTextureFromFile(markerFilename, true, false)
			if v39_ ~= 0 and v39_ ~= nil then
				if v37_.markerTexture ~= nil then
					delete(v37_.markerTexture)
				end
				v37_.markerTexture = v39_
			end
		end
	else
		Logging.warning("\'%s\' is not a valid name for a tree marker type!", (tostring(name)))
	end
end

-- Local values: treeMarkers, splitShapeId, data, treeMarker
function TreeMarkerSystem:onClientJoined(connection)
	local v42_ = {}
	for v43_, v44_ in pairs(self.treeMarkers) do
		if entityExists(v43_) then
			local v45_ = {
				["splitShapeId"] = v44_.splitShapeId,
				["treeMarkerTypeIndex"] = v44_.treeMarkerTypeIndex,
				["r"] = v44_.r,
				["g"] = v44_.g,
				["b"] = v44_.b,
				["a"] = v44_.a,
				["posX"] = v44_.posX,
				["posY"] = v44_.posY,
				["scale"] = v44_.scale,
				["rotY"] = v44_.rotY
			}
			table.insert(v42_, v45_)
			if #v42_ == 255 then
				connection:sendEvent(TreeMarkerEvent.new(v42_))
				v42_ = {}
			end
		else
			self.treeMarkers[v43_] = nil
		end
	end
	if #v42_ > 0 then
		connection:sendEvent(TreeMarkerEvent.new(v42_))
	end
end

-- Local values: xmlFile, i, shapeId, treeMarker, splitShapePart1, splitShapePart2, splitShapePart3, key, treeMarkerType
function TreeMarkerSystem:saveToXMLFile(xmlPath, usedModNames)
	if xmlPath ~= nil then
		local v48_ = XMLFile.create("TreeMarkerSystemSavegameXML", xmlPath, "treeMarkerSystem", TreeMarkerSystem.xmlSchemaSavegame)
		if v48_ ~= nil then
			local v49_ = 0
			for v50_, v51_ in pairs(self.treeMarkers) do
				if entityExists(v50_) then
					local v52_, v53_, v54_ = getSaveableSplitShapeId(v50_)
					if v52_ ~= 0 and v52_ ~= nil then
						local v55_ = string.format("treeMarkerSystem.treeMarkers.treeMarker(%d)", v49_)
						v48_:setValue(v55_ .. "#splitShapePart1", v52_)
						v48_:setValue(v55_ .. "#splitShapePart2", v53_)
						v48_:setValue(v55_ .. "#splitShapePart3", v54_)
						local v56_ = self:getTreeMarkerTypeByIndex(v51_.treeMarkerTypeIndex)
						v48_:setValue(v55_ .. "#type", v56_.name)
						v48_:setValue(v55_ .. "#color", v51_.r, v51_.g, v51_.b, v51_.a)
						v48_:setValue(v55_ .. "#scale", v51_.scale)
						v48_:setValue(v55_ .. "#posX", v51_.posX)
						v48_:setValue(v55_ .. "#posY", v51_.posY)
						local v57_ = v55_ .. "#rotY"
						local v58_ = v51_.rotY
						v48_:setValue(v57_, (math.deg(v58_)))
						v49_ = v49_ + 1
					end
				else
					self.treeMarkers[v50_] = nil
				end
			end
			v48_:save()
			v48_:delete()
		end
	end
end

-- Local values: xmlFile, _, key, treeMarkerTypeName, treeMarkerType, splitShapePart1, splitShapePart2, splitShapePart3, shapeId, r, g, b, a, posX, posY, scale, rotY
function TreeMarkerSystem:loadFromSavegameXML(xmlPath)
	if xmlPath ~= nil then
		local v61_ = XMLFile.loadIfExists("TreeMarkerSystemSavegameXML", xmlPath, TreeMarkerSystem.xmlSchemaSavegame)
		if v61_ ~= nil then
			for _, v62_ in v61_:iterator("treeMarkerSystem.treeMarkers.treeMarker") do
				local v63_ = v61_:getValue(v62_ .. "#type")
				if v63_ ~= nil then
					local v64_ = self:getTreeMarkerTypeByName(v63_)
					if v64_ ~= nil then
						local v65_ = v61_:getValue(v62_ .. "#splitShapePart1")
						if v65_ ~= nil then
							local v66_ = v61_:getValue(v62_ .. "#splitShapePart2")
							local v67_ = v61_:getValue(v62_ .. "#splitShapePart3")
							local v68_ = getShapeFromSaveableSplitShapeId(v65_, v66_, v67_)
							if v68_ ~= nil and v68_ ~= 0 then
								local v69_, v70_, v71_, v72_ = v61_:getValue(v62_ .. "#color", {
									1,
									1,
									1,
									1
								}, false)
								local v73_ = v61_:getValue(v62_ .. "#posX", 0)
								local v74_ = v61_:getValue(v62_ .. "#posY", 0)
								local v75_ = v61_:getValue(v62_ .. "#scale", 0.4)
								local v76_ = v61_:getValue(v62_ .. "#rotY", 0)
								local v77_ = math.rad(v76_)
								self:addTreeMarker(v68_, v64_.index, v69_, v70_, v71_, v72_, v73_, v74_, v75_, v77_)
							end
						end
					end
				end
			end
			v61_:delete()
		end
	end
end

function TreeMarkerSystem:getTreeMarkerTypeByIndex(index)
	return self.treeMarkerTypes[index]
end

function TreeMarkerSystem:getTreeMarkerTypeByName(name)
	if ClassUtil.getIsValidIndexName(name) then
		local v82_ = string.upper(name)
		return self.nameToTreeMarkerType[v82_]
	else
		Logging.warning("\'%s\' is not a valid name for a tree marker type!", (tostring(name)))
		return nil
	end
end

function TreeMarkerSystem:getNumOfTreeMarkerTypes()
	return #self.treeMarkerTypes
end

-- Local values: treeMarkerType, _, localHitY, _, localCamX, _, localCamZ, localDirX, localDirZ, angle, posX, posY, scale
function TreeMarkerSystem:addTreeMarkerCameraBased(shapeId, treeMarkerTypeIndex, r, g, b, a, camX, camY, camZ, hitX, hitY, hitZ, noEventSend)
	local v98_ = treeMarkerTypeIndex or 0
	local v99_ = self:getTreeMarkerTypeByIndex(v98_)
	if v99_ == nil then
		Logging.warning("No tree marker type found for tree marker type index \'%d\'", v98_)
	else
		local _, v100_, _ = worldToLocal(shapeId, hitX, hitY, hitZ)
		local v101_, _, v102_ = worldToLocal(shapeId, camX, camY, camZ)
		local v103_, v104_ = MathUtil.vector2Normalize(v101_, v102_)
		local v105_ = math.atan2(v103_, v104_)
		self:addTreeMarker(shapeId, v98_, r, g, b, a, 0, v100_, v99_.scale or 0.4, v105_, noEventSend)
	end
end

-- Local values: treeMarkerType, localDirX, _, localDirZ, angle, posX, posY
function TreeMarkerSystem:addTreeMarkerByWorldDirection(shapeId, treeMarkerTypeIndex, r, g, b, a, dirX, dirZ, yOffset, scale, noEventSend)
	local v118_ = treeMarkerTypeIndex or 0
	local v119_ = self:getTreeMarkerTypeByIndex(v118_)
	if v119_ == nil then
		Logging.warning("No tree marker type found for tree marker type index \'%d\'", v118_)
	else
		local v120_, _, v121_ = worldDirectionToLocal(shapeId, dirX, 0, dirZ)
		local v122_ = math.atan2(v120_, v121_)
		self:addTreeMarker(shapeId, v118_, r, g, b, a, 0, yOffset, scale or (v119_.scale or 0.4), v122_, noEventSend)
	end
end

-- Local values: treeMarker, treeMarkerType, material, newMaterialId
function TreeMarkerSystem:addTreeMarker(splitShapeId, treeMarkerTypeIndex, r, g, b, a, posX, posY, scale, rotY, noEventSend)
	if self.isServer and (noEventSend == nil or noEventSend == false) then
		g_server:broadcastEvent(TreeMarkerEvent.new({
			{
				["splitShapeId"] = splitShapeId,
				["treeMarkerTypeIndex"] = treeMarkerTypeIndex,
				["r"] = r,
				["g"] = g,
				["b"] = b,
				["a"] = a,
				["posX"] = posX,
				["posY"] = posY,
				["scale"] = scale,
				["rotY"] = rotY
			}
		}), false)
	end
	if splitShapeId ~= nil and entityExists(splitShapeId) then
		local v135_ = self:getTreeMarkerTypeByIndex(treeMarkerTypeIndex)
		if v135_ ~= nil and v135_.markerTexture ~= nil then
			local v136_ = getMaterial(splitShapeId, 0)
			local v137_ = setMaterialCustomMap(v136_, self.shaderParameterMap, v135_.markerTexture, false)
			setMaterial(splitShapeId, v137_, 0)
		end
		if getHasShaderParameter(splitShapeId, self.shaderParameter) then
			setShaderParameter(splitShapeId, self.shaderParameter, posX, posY, scale, rotY, false)
		end
		if getHasShaderParameter(splitShapeId, self.shaderParameterColor) then
			setShaderParameter(splitShapeId, self.shaderParameterColor, r, g, b, a, false)
		end
		self.treeMarkers[splitShapeId] = {
			["splitShapeId"] = splitShapeId,
			["treeMarkerTypeIndex"] = treeMarkerTypeIndex,
			["r"] = r,
			["g"] = g,
			["b"] = b,
			["a"] = a,
			["posX"] = posX,
			["posY"] = posY,
			["scale"] = scale,
			["rotY"] = rotY
		}
	end
end
