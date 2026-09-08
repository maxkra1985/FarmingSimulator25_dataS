-- Local values: Mission00_mt
Mission00 = {}
local Mission00_mt = Class(Mission00, FSBaseMission)
g_xmlManager:addCreateSchemaFunction(function()
	Mission00.xmlSchema = XMLSchema.new("mission00")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = Mission00.xmlSchema
	v2_:register(XMLValueType.STRING, "map.filename", "filepath to map i3d file", nil, true)
	v2_:register(XMLValueType.INT, "map#width", "Width of the world", 2048)
	v2_:register(XMLValueType.INT, "map#height", "Height of the world", 2048)
	v2_:register(XMLValueType.STRING, "map#imageFilename", "2D map filename")
	v2_:register(XMLValueType.VECTOR_3, "map#mapFieldColor", "2D map field color rgb")
	v2_:register(XMLValueType.VECTOR_3, "map#mapGrassFieldColor", "2D map grass color rgb")
	v2_:register(XMLValueType.FLOAT, "map.culling#xzOffset", "")
	v2_:register(XMLValueType.FLOAT, "map.culling#minY", "")
	v2_:register(XMLValueType.FLOAT, "map.culling#maxY", "")
	v2_:register(XMLValueType.FLOAT, "map.culling#clipDistanceThreshold1", "")
	v2_:register(XMLValueType.FLOAT, "map.culling#clipDistanceThreshold2", "")
	v2_:register(XMLValueType.INT, "map.densityMap#revision", "")
	v2_:register(XMLValueType.INT, "map.terrainTexture#revision", "")
	v2_:register(XMLValueType.INT, "map.terrainLodTexture#revision", "")
	v2_:register(XMLValueType.INT, "map.splitShapes#revision", "")
	v2_:register(XMLValueType.INT, "map.tipCollision#revision", "")
	v2_:register(XMLValueType.INT, "map.placementCollision#revision", "")
	v2_:register(XMLValueType.INT, "map.navigationCollision#revision", "")
	v2_:register(XMLValueType.FLOAT, "map.vertexBufferMemoryUsage", "")
	v2_:register(XMLValueType.FLOAT, "map.indexBufferMemoryUsage", "")
	v2_:register(XMLValueType.FLOAT, "map.textureMemoryUsage", "")
	v2_:register(XMLValueType.STRING, "map.shop#filename", "")
	v2_:register(XMLValueType.STRING, "map.storeItems#filename", "")
	v2_:register(XMLValueType.STRING, "map.sounds#filename", "")
	v2_:register(XMLValueType.STRING, "map.environment#filename", "")
	v2_:register(XMLValueType.STRING, "map.environmentAreaSystem#outOfBoundsAreaType", "AreaType to use for EnvironmentAreaSystem if the requested posities lies outside of the map bounds / bitmap")
	v2_:register(XMLValueType.STRING, "map.weed#filename", "")
	v2_:register(XMLValueType.STRING, "map.fieldGround#filename", "")
	v2_:register(XMLValueType.STRING, "map.motionPathEffects#filename", "")
	v2_:register(XMLValueType.STRING, "map.bales#filename", "")
	v2_:register(XMLValueType.STRING, "map.helpers#filename", "")
	v2_:register(XMLValueType.STRING, "map.densityHeightTypes#filename", "")
	v2_:register(XMLValueType.STRING, "map.fillTypes#filename", "")
	v2_:register(XMLValueType.STRING, "map.groundTypes#filename", "")
	v2_:register(XMLValueType.STRING, "map.sprayTypes#filename", "")
	v2_:register(XMLValueType.STRING, "map.animals#filename", "")
	v2_:register(XMLValueType.STRING, "map.animals.food#filename", "")
	v2_:register(XMLValueType.STRING, "map.animals.names#filename", "")
	v2_:register(XMLValueType.STRING, "map.wildlife#filename", "")
	v2_:register(XMLValueType.STRING, "map.aiSystem#filename", "")
	v2_:register(XMLValueType.STRING, "map.licensePlates#filename", "")
	v2_:register(XMLValueType.STRING, "map.helpline#filename", "")
	v2_:register(XMLValueType.VECTOR_TRANS, "map.helpline.trigger(?)#position", "")
	v2_:register(XMLValueType.INT, "map.helpline.trigger(?)#categoryIndex", "")
	v2_:register(XMLValueType.INT, "map.helpline.trigger(?)#pageIndex", "")
	v2_:register(XMLValueType.STRING, "map.gameplayHints#filename", "")
	v2_:register(XMLValueType.STRING, "map.collectibles#filename", "")
	v2_:register(XMLValueType.STRING, "map.additionalFiles.additionalFile(?)#filename", "Path to additional i3d- or xml files to load for the map")
	v2_:register(XMLValueType.STRING, "map.decoFoliages.decoFoliage(?)#layerName", "")
	v2_:register(XMLValueType.INT, "map.decoFoliages.decoFoliage(?)#startChannel", "")
	v2_:register(XMLValueType.INT, "map.decoFoliages.decoFoliage(?)#numChannels", "")
	v2_:register(XMLValueType.BOOL, "map.decoFoliages.decoFoliage(?)#mowable", "")
	v2_:register(XMLValueType.STRING, "map.decoFoliages.mapping(?)#name", "")
	v2_:register(XMLValueType.STRING, "map.decoFoliages.mapping(?)#layerName", "")
	v2_:register(XMLValueType.INT, "map.decoFoliages.mapping(?)#state", "")
	v2_:register(XMLValueType.STRING, "map.paintableFoliages.paintableFoliage(?)#layerName", "")
	v2_:register(XMLValueType.INT, "map.paintableFoliages.paintableFoliage(?)#startChannel", "")
	v2_:register(XMLValueType.INT, "map.paintableFoliages.paintableFoliage(?)#numStateChannels", "")
	v2_:register(XMLValueType.STRING, "map.groundTypeMappings.groundTypeMapping(?)#type", "")
	v2_:register(XMLValueType.STRING, "map.groundTypeMappings.groundTypeMapping(?)#title", "")
	v2_:register(XMLValueType.STRING, "map.groundTypeMappings.groundTypeMapping(?)#layer", "")
	v2_:register(XMLValueType.STRING, "map.hotspots.placeableHotspot(?)#type", "Placeable hotspot type")
	v2_:register(XMLValueType.VECTOR_2, "map.hotspots.placeableHotspot(?)#worldPosition", "Placeable world position")
	v2_:register(XMLValueType.VECTOR_3, "map.hotspots.placeableHotspot(?)#teleportWorldPosition", "Placeable teleport world position")
	v2_:register(XMLValueType.STRING, "map.hotspots.placeableHotspot(?)#text", "Placeable hotspot text")
end)

-- Upvalues: Mission00_mt
-- Local values: self
function Mission00.new(baseDirectory, custom_mt)
	-- upvalues: (copy) Mission00_mt
	local v5_ = Mission00:superClass().new(baseDirectory, custom_mt or Mission00_mt)
	if g_dedicatedServer ~= nil then
		v5_:setAutoSaveInterval(g_dedicatedServer.autoSaveInterval, true)
	end
	v5_.isSaving = false
	g_mission00StartPoint = nil
	v5_.gameStarted = false
	v5_.mapHotspots = {}
	return v5_
end

-- Local values: _, hotspot
function Mission00:delete()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)
		self.xmlFile = nil
	end
	g_autoSaveManager:unloadMapData()
	for _, v7_ in ipairs(self.mapHotspots) do
		self:removeMapHotspot(v7_)
		v7_:delete()
	end
	Mission00:superClass().delete(self)
end

-- Local values: mapXMLFilename, xmlFile
function Mission00:setMissionInfo(missionInfo, missionDynamicInfo)
	local v11_ = Utils.getFilename(missionInfo.mapXMLFilename, self.baseDirectory)
	local v12_ = XMLFile.load("MapXML", v11_, Mission00.xmlSchema)
	self.xmlFile = v12_:getHandle()
	self.mapWidth = v12_:getValue("map#width", 2048)
	self.mapHeight = v12_:getValue("map#height", 2048)
	self.mapImageFilename = Utils.getFilename(v12_:getValue("map#imageFilename"), self.baseDirectory)
	self.mapFieldColor = v12_:getValue("map#mapFieldColor", nil, true) or { 0.15, 0.1195, 0.0953 }
	self.mapGrassFieldColor = v12_:getValue("map#mapGrassFieldColor", nil, true) or { 0.147, 0.1441, 0.0823 }
	self.cullingWorldXZOffset = v12_:getValue("map.culling#xzOffset", self.cullingWorldXZOffset)
	self.cullingWorldMinY = v12_:getValue("map.culling#minY", self.cullingWorldMinY)
	self.cullingWorldMaxY = v12_:getValue("map.culling#maxY", self.cullingWorldMaxY)
	self.cullingClipDistanceThreshold1 = v12_:getValue("map.culling#clipDistanceThreshold1", self.cullingClipDistanceThreshold1)
	self.cullingClipDistanceThreshold2 = v12_:getValue("map.culling#clipDistanceThreshold2", self.cullingClipDistanceThreshold2)
	self.mapDensityMapRevision = v12_:getValue("map.densityMap#revision", 1)
	self.mapTerrainTextureRevision = v12_:getValue("map.terrainTexture#revision", 1)
	self.mapTerrainLodTextureRevision = v12_:getValue("map.terrainLodTexture#revision", 1)
	self.mapSplitShapesRevision = v12_:getValue("map.splitShapes#revision", 1)
	self.mapTipCollisionRevision = v12_:getValue("map.tipCollision#revision", 1)
	self.mapPlacementCollisionRevision = v12_:getValue("map.placementCollision#revision", 1)
	self.mapNavigationCollisionRevision = v12_:getValue("map.navigationCollision#revision", 1)
	self.vertexBufferMemoryUsage = v12_:getValue("map.vertexBufferMemoryUsage", self.vertexBufferMemoryUsage)
	self.indexBufferMemoryUsage = v12_:getValue("map.indexBufferMemoryUsage", self.indexBufferMemoryUsage)
	self.textureMemoryUsage = v12_:getValue("map.textureMemoryUsage", self.textureMemoryUsage)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_gameplayHintManager:loadMapData(self.xmlFile, missionInfo)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.navigationSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.slotSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.fieldGroundSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.aiMessageManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		self.aiJobTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_wheelManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_treePlantManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.treeMarkerSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_vehicleMaterialManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_storeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.STORE)
	end, "Mission00:setMissionInfo - StoreManager:loadMapData")
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_groundTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_connectionHoseManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_consumableManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_fillTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_fruitTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_baleManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.weedSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.stoneSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.aiSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.animalSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end, "Mission00:setMissionInfo - AnimalSystem:loadMapData")
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.animalFoodSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_sleepManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		self.animalNameSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_densityMapHeightManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_npcManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo
		g_helperManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo, (copy) missionDynamicInfo
		g_materialManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory, function()
			-- upvalues: (ref) self, (ref) missionInfo, (ref) missionDynamicInfo
			self:onMaterialsLoaded(missionInfo, missionDynamicInfo)
		end)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo, (copy) missionDynamicInfo
		Mission00:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
	end)
end

function Mission00:onMaterialsLoaded(missionInfo, missionDynamicInfo)
	if not self.cancelLoading then
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self, (copy) missionInfo
			g_licensePlateManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			g_particleSystemManager:loadMapData()
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self, (copy) missionInfo
			g_motionPathEffectManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			g_effectManager:loadMapData()
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self, (copy) missionInfo
			self.foliageSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			g_fillTypeManager:loadModFillTypes()
			g_densityMapHeightManager:loadModDensityMapHeightTypes()
			g_motionPathEffectManager:loadQueuedModMotionPathEffects()
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self, (copy) missionInfo
			g_sprayTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
			g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.DATA)
		end)
	end
end

-- Local values: mapFilename, soundFilename
function Mission00:load()
	self:startLoadingTask()
	self:loadEnvironment(self.xmlFile)
	local v16_ = getXMLString(self.xmlFile, "map.filename")
	local v17_ = Utils.getFilename(v16_, self.baseDirectory)
	Logging.info("Loading map: %s", v17_)
	self:loadMap(v17_, true, self.loadMission00Finished, self)
	local v18_ = Utils.getNoNil(getXMLString(self.xmlFile, "map.sounds#filename"), "$data/maps/map01_sound.xml")
	local v19_ = Utils.getFilename(v18_, self.baseDirectory)
	self.missionInfo.mapSoundXmlFilename = v19_
	self:loadMapSounds(v19_, self.baseDirectory)
	self.ambientSoundSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.environmentAreaSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.reverbSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.collectiblesSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.growthSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.snowSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
end

function Mission00:loadMission00Finished(node, arguments)
	if not self.cancelLoading then
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			local function v21_()
				-- upvalues: (ref) self
				self.numAdditionalFiles = self.numAdditionalFiles - 1
				if self.numAdditionalFiles == 0 then
					self:loadAdditionalFilesFinished()
				end
			end
			local v22_ = self:loadAdditionalFiles(self.xmlFile, v21_, nil)
			if v22_ > 0 then
				self.numAdditionalFiles = v22_
			else
				self:loadAdditionalFilesFinished()
			end
		end)
	end
end

function Mission00:loadAdditionalFilesFinished()
	if not self.cancelLoading then
		g_asyncTaskManager:addTask(function()
			g_materialManager:loadModMaterialHolders()
			g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self.hud:loadIngameMap(self.mapImageFilename, self.mapWidth, self.mapHeight, self.mapFieldColor, self.mapGrassFieldColor)
		end, "Mission00:loadAdditionalFilesFinished - Load Ingamemap")
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self:loadHotspots(self.xmlFile, self.missionInfo.customEnvironment)
		end, "Mission00:loadAdditionalFilesFinished - Load Hotspots")
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self.handToolSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_farmlandManager:loadMapData(self.xmlFile)
		end, "Mission00:loadAdditionalFilesFinished - FarmlandManager:loadMapData")
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_guidedTourManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_fieldManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_fieldCourseManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_farmManager:loadMapData(self.xmlFile)
			if self.missionDynamicInfo.isMultiplayer then
				self:loadCompetitiveMultiplayer(self.xmlFile)
			end
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self.placeableSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self:loadPlaceables(self.missionInfo.placeablesXMLLoad)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_missionManager:loadMapData(self.xmlFile)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_helpLineManager:loadMapData(self.xmlFile, self.missionInfo)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_gui:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			if self:getIsServer() and (self.missionInfo.savegameDirectory ~= nil and fileExists(self.missionInfo.savegameDirectory .. "/collectibles.xml")) then
				self.collectiblesSystem:loadFromXMLFile(self.missionInfo.savegameDirectory .. "/collectibles.xml")
			end
		end)
		g_asyncTaskManager:addTask(function()
			g_autoSaveManager:loadFinished()
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			if self.missionDynamicInfo.isMultiplayer then
				self:removeAllHelpIcons()
			else
				self:updateFoundHelpIcons()
			end
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			if self.xmlFile ~= nil then
				delete(self.xmlFile)
				self.xmlFile = nil
			end
		end)
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			Mission00:superClass().load(self)
			if self.missionInfo.economyXMLLoad ~= nil then
				self:loadEconomy(self.missionInfo.economyXMLLoad)
			end
		end)
		if self:getIsServer() then
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				if self.missionInfo.fieldsXMLLoad ~= nil then
					g_fieldManager:loadFromXMLFile(self.missionInfo.fieldsXMLLoad)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				g_farmManager:loadFromXMLFile(self.missionInfo.farmsXMLLoad)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				g_farmlandManager:loadFromXMLFile(self.missionInfo.farmlandXMLLoad)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				g_missionManager:loadFromXMLFile(self.missionInfo.missionsXMLLoad)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				g_guidedTourManager:loadFromXMLFile(self.missionInfo.guidedTourXMLLoad)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				if self.missionInfo.playersXMLLoad ~= nil then
					self.playerSystem:loadFromSavegameXML(self.missionInfo.playersXMLLoad)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				g_npcManager:loadFromSavegameXMLFile(self.missionInfo.npcXMLLoad)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				self.vehicleSaleSystem:loadFromXMLFile(self.missionInfo.vehicleSaleXML)
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				if self.missionInfo.treeMarkerXMLLoad ~= nil then
					self.treeMarkerSystem:loadFromSavegameXML(self.missionInfo.treeMarkerXMLLoad)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				if self.missionInfo.destructibleMapObjectsXMLLoad ~= nil then
					self.destructibleMapObjectSystem:loadFromSavegameXML(self.missionInfo.destructibleMapObjectsXMLLoad)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				self.growthSystem:loadFromXMLFile(self.missionInfo.environmentXMLLoad)
				if self.missionInfo.environmentXMLLoad ~= nil then
					self.snowSystem:loadFromXMLFile(self.missionInfo.environmentXMLLoad)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				if self.missionInfo.aiSystemXMLLoad ~= nil then
					self.aiSystem:loadFromXMLFile(self.missionInfo.aiSystemXMLLoad)
				end
			end)
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				if self.missionInfo.navigationSystemXMLLoad ~= nil then
					self.aiSystem:loadFromXMLFile(self.missionInfo.navigationSystemXMLLoad)
				end
			end)
		end
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			g_treePlantManager:loadFromXMLFile(self.missionInfo.treePlantXMLLoad)
		end, "TreePlantManager:loadFromXMLFile")
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			self:finishLoadingTask()
		end)
	end
end

-- Local values: i, numFiles, key, filename, externalXMLFile
function Mission00:loadAdditionalFiles(xmlFile, callbackFunc, callbackTarget)
	local v28_ = 0
	local v_u_29_ = 0
	while true do
		local v30_ = string.format("map.additionalFiles.additionalFile(%d)", v28_)
		if not hasXMLProperty(xmlFile, v30_) then
			break
		end
		local v_u_31_ = getXMLString(xmlFile, v30_ .. "#filename")
		if v_u_31_ ~= nil then
			if v_u_31_:contains(".i3d") then
				g_asyncTaskManager:addSubtask(function()
					-- upvalues: (ref) v_u_31_, (copy) self, (copy) callbackFunc, (copy) callbackTarget
					v_u_31_ = Utils.getFilename(v_u_31_, self.baseDirectory)
					local v32_ = { callbackFunc, callbackTarget }
					g_i3DManager:loadI3DFileAsync(v_u_31_, true, true, self.onLoadedMapI3DFiles, self, v32_)
				end)
				v_u_29_ = v_u_29_ + 1
			elseif v_u_31_:contains(".xml") then
				local v33_ = Utils.getFilename(v_u_31_, self.baseDirectory)
				local v_u_34_ = XMLFile.load("additionalFilesXML", v33_)
				if v_u_34_ ~= nil then
					v_u_34_:iterate("additionalFiles.additionalFile", function(_, p35_)
						-- upvalues: (copy) v_u_34_, (copy) self, (copy) callbackFunc, (copy) callbackTarget, (ref) v_u_29_
						local v36_ = v_u_34_:getString(p35_ .. "#filename")
						if v36_ ~= nil then
							local v37_ = Utils.getFilename(v36_, self.baseDirectory)
							local v38_ = { callbackFunc, callbackTarget }
							g_i3DManager:loadI3DFileAsync(v37_, true, true, self.onLoadedMapI3DFiles, self, v38_)
							v_u_29_ = v_u_29_ + 1
						end
					end)
					v_u_34_:delete()
				end
			end
		end
		v28_ = v28_ + 1
	end
	return v_u_29_
end

-- Local values: callbackFunc, callbackTarget
function Mission00:onLoadedMapI3DFiles(node, failedReason, args)
	if node ~= 0 then
		unlink(node)
		local v42_ = self.dynamicallyLoadedObjects
		table.insert(v42_, node)
	end
	args[1](args[2])
end

-- Local values: i, key, hotspot, text, hotspotTypeName, hotspotType, worldPositionX, worldPositionZ, teleportX, teleportY, teleportZ
function Mission00:loadHotspots(xmlFile, customEnvironment)
	local v46_ = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
	local v47_ = 0
	while true do
		local v48_ = string.format("map.hotspots.placeableHotspot(%d)", v47_)
		if not v46_:hasProperty(v48_) then
			break
		end
		local v49_ = PlaceableHotspot.new()
		local v50_ = v46_:getValue(v48_ .. "#text", nil)
		if v50_ == nil then
			Logging.xmlWarning(v46_, "Missing placeable hotspot name for \'%s\'", v48_)
			break
		end
		v49_:setName(g_i18n:convertText(v50_, customEnvironment))
		v49_:createIcon()
		local v51_ = v46_:getValue(v48_ .. "#type", "UNLOADING")
		local v52_ = PlaceableHotspot.getTypeByName(v51_)
		if v52_ == nil then
			Logging.xmlWarning(v46_, "Unknown placeable hotspot type \'%s\'. Falling back to type \'UNLOADING\'\nAvailable types: %s", v51_, table.concatKeys(PlaceableHotspot.TYPE, " "))
			v52_ = PlaceableHotspot.TYPE.UNLOADING
		end
		v49_:setPlaceableType(v52_)
		local v53_, v54_ = v46_:getValue(v48_ .. "#worldPosition", nil)
		if v53_ ~= nil then
			v49_:setWorldPosition(v53_, v54_)
		end
		local v55_, v56_, v57_ = v46_:getValue(v48_ .. "#teleportWorldPosition", nil)
		if v55_ ~= nil then
			local v58_ = getTerrainHeightAtWorldPos
			local v59_ = g_terrainNode
			v49_:setTeleportWorldPosition(v55_, math.max(v56_, v58_(v59_, v55_, 0, v57_)), v57_)
		end
		self:addMapHotspot(v49_)
		local v60_ = self.mapHotspots
		table.insert(v60_, v49_)
		v47_ = v47_ + 1
	end
	v46_:delete()
end

function Mission00:onStartMission()
	Mission00:superClass().onStartMission(self)
	g_gameStateManager:setGameState(GameState.PLAY)
	g_achievementManager:loadMapData()
	g_currentMission.economyManager:restartGreatDemands()
	g_messageCenter:publish(MessageType.CURRENT_MISSION_START, not self.missionInfo.isValid)
	self.gameStarted = true
end

function Mission00:getIsTourSupported()
	if Profiler.IS_INITIALIZED then
		return false
	elseif self.missionInfo.startWithGuidedTour then
		return self.missionInfo.loadDefaultFarm and true or false
	else
		return false
	end
end

function Mission00:update(dt)
	Mission00:superClass().update(self, dt)
	if self:getIsServer() then
		g_autoSaveManager:update(dt)
		self.isSaving = g_savegameController:getIsSaving()
		if (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) and not self.isSaving then
			self:tryUnpauseGame()
		end
	end
end

function Mission00:doPauseGame()
	Mission00:superClass().doPauseGame(self)
	self:showPauseDisplay(true)
end

function Mission00:doUnpauseGame()
	Mission00:superClass().doUnpauseGame(self)
	self:showPauseDisplay(false)
end

function Mission00:canUnpauseGame()
	local v68_ = Mission00:superClass().canUnpauseGame(self)
	if v68_ then
		v68_ = not self.isSaving
	end
	return v68_
end

function Mission00:draw()
	Mission00:superClass().draw(self)
	if self.missionDynamicInfo.isMultiplayer and self.gameStarted then
		self.hud:drawCommunicationDisplay()
	end
end

function Mission00:loadPlaceables(xmlFilename)
	if xmlFilename ~= nil and self:getIsServer() then
		self:startLoadingTask()
		self.placeableSystem:load(xmlFilename, self.onFinishedPlaceables, self)
	end
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) self
		self:loadVehicles(self.missionInfo.vehiclesXMLLoad)
	end)
end

function Mission00:onFinishedPlaceables()
	g_farmManager:mergeObjectsForSingleplayer()
	self:finishLoadingTask()
	g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES)
end

function Mission00:loadVehicles(xmlFilename)
	if xmlFilename ~= nil and self:getIsServer() then
		self:startLoadingTask()
		self.vehicleSystem:load(xmlFilename, self.onFinishedVehicles, self)
	end
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) self
		self:loadHandTools(self.missionInfo.handToolsXMLLoad)
	end)
end

function Mission00:onFinishedVehicles(loadedVehicles, vehicleLoadingState, callbackArguments)
	g_farmManager:mergeObjectsForSingleplayer()
	self:finishLoadingTask()
	g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_VEHICLES)
end

function Mission00:loadHandTools(xmlFilename)
	if self:getIsServer() then
		self:startLoadingTask()
		self.handToolSystem:load(xmlFilename, self.onFinishedHandTools, self)
	end
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) self
		if self:getIsServer() then
			g_messageCenter:publish(MessageType.ENQUEUED_ALL_LOADINGS)
		end
		self:loadItems(self.missionInfo.itemsXMLLoad)
	end)
end

function Mission00:onFinishedHandTools()
	g_farmManager:mergeObjectsForSingleplayer()
	self:finishLoadingTask()
	g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_HANDTOOLS)
end

function Mission00:loadItems(xmlFilename, resetItems)
	if xmlFilename == nil then
		self:loadItemsFinished()
	else
		self:startLoadingTask()
		self.itemSystem:loadItems(xmlFilename, resetItems, self.missionInfo, self.missionDynamicInfo, self.loadItemsFinished, self, nil)
	end
end

function Mission00:loadItemsFinished()
	if self:getIsServer() then
		g_asyncTaskManager:addSubtask(function()
			g_farmManager:mergeObjectsForSingleplayer()
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self
			if self.missionInfo.onCreateObjectsXMLLoad ~= nil then
				self.onCreateObjectSystem:load(self.missionInfo.onCreateObjectsXMLLoad)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self
			self:finishLoadingTask()
		end)
	end
end

function Mission00:onCreateStartPoint(id)
	g_mission00StartPoint = id
end

-- Local values: isAllowed, user
function Mission00:addChatMessage(sender, msg, farmId, userId)
	local v89_ = true
	if userId ~= nil then
		local v90_ = self.userManager:getUserByUserId(userId, false)
		if v90_ ~= nil then
			sender = v90_:getNickname()
			v89_ = v90_:getAllowTextCommunication()
		end
	end
	if v89_ then
		self.hud:addChatMessage(msg, sender, farmId)
	end
end

function Mission00:scrollChatMessages(delta)
	self.hud:scrollChatMessages(delta)
end

-- Local values: xmlFile
function Mission00:loadEconomy(xmlFilename)
	if self:getIsServer() then
		local v95_ = loadXMLFile("economyXML", xmlFilename)
		g_currentMission.economyManager:loadFromXMLFile(v95_, "economy")
		delete(v95_)
	end
end

-- Local values: filename, farmXmlFile, i, farmKey, farmId, name, color, farm, money, loan
function Mission00:loadCompetitiveMultiplayer(xmlFile)
	local v98_ = getXMLString(xmlFile, "map.competitiveMultiplayer#filename")
	if v98_ ~= nil and self:getIsServer() then
		local v99_ = Utils.getFilename(v98_, self.baseDirectory)
		if not self.missionInfo.isValid then
			local v100_ = loadXMLFile("CompetitiveXML", v99_)
			local v101_ = 0
			while true do
				local v102_ = string.format("competitiveMultiplayer.farms.farm(%d)", v101_)
				if not hasXMLProperty(v100_, v102_) then
					break
				end
				local v103_ = getXMLInt(v100_, v102_ .. "#farmId")
				local v104_ = getXMLString(v100_, v102_ .. "#name")
				local v105_ = getXMLInt(v100_, v102_ .. "#color")
				local v106_ = g_farmManager:createFarm(v104_, v105_, nil, v103_)
				if v106_ ~= nil then
					local v107_ = getXMLFloat(v100_, v102_ .. "#money")
					if v107_ ~= nil then
						v106_.money = v107_
					end
					local v108_ = getXMLFloat(v100_, v102_ .. "#loan")
					if v108_ ~= nil then
						v106_.loan = v108_
					end
				end
				v101_ = v101_ + 1
			end
			delete(v100_)
		end
		self.missionInfo.isCompetitiveMultiplayer = true
	end
end
