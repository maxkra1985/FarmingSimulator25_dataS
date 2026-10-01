MeadowCreationTask = {}
local MeadowCreationTask_mt = Class(MeadowCreationTask, FieldUpdateTask)
function MeadowCreationTask.registerXMLPaths(schema, basePath)
	FieldUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".terrainGroundType#name", "Name of the terrain ground type", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".decoFoliage#name", "Name of the deco foliage", nil, false)
end
function MeadowCreationTask.new(customMt)
	local self = MeadowCreationTask:superClass().new(customMt or MeadowCreationTask_mt)
	self.terrainGroundType = nil
	self.decoFoliageName = nil
	self.deformation = nil
	return self
end
function MeadowCreationTask:saveToXMLFile(xmlFile, key)
	MeadowCreationTask:superClass().saveToXMLFile(self, xmlFile, key)
	if self.terrainGroundType ~= nil then
		xmlFile:setValue(key .. ".terrainGroundType#name", self.terrainGroundType)
	end
	if self.decoFoliageName ~= nil then
		xmlFile:setValue(key .. ".decoFoliage#name", self.decoFoliageName)
	end
end
function MeadowCreationTask:loadFromXMLFile(xmlFile, key)
	local terrainGroundType = xmlFile:getValue(key .. ".terrainGroundType#name")
	if terrainGroundType ~= nil then
		self:setTerrainGroundType(terrainGroundType)
	end
	local decoFoliage = xmlFile:getValue(key .. ".decoFoliage#name")
	if decoFoliage ~= nil then
		self:setDecoFoliage(decoFoliage)
	end
	return MeadowCreationTask:superClass().loadFromXMLFile(self, xmlFile, key)
end
function MeadowCreationTask:setDecoFoliage(decoFoliageName)
	if not g_currentMission.foliageSystem:getIsDecoLayerDefined(decoFoliageName) then
		Logging.warning("MeadowCreationTask.setDecoFoliage: DecoFoliage '%s' not defined on current map ", decoFoliageName)
	else
		self.decoFoliageName = decoFoliageName
	end
end
function MeadowCreationTask:setTerrainGroundType(terrainGroundType)
	local layerId = g_groundTypeManager:getTerrainLayerByType(terrainGroundType)
	if layerId == nil then
		Logging.warning("MeadowCreationTask.setTerrainGroundType: Terrain Ground Type '%s' not supported by map", terrainGroundType)
	else
		self.terrainGroundType = terrainGroundType
	end
end
function MeadowCreationTask:prepare()
	MeadowCreationTask:superClass().prepare(self)
	if self.decoFoliageName ~= nil then
		local mapId, startChannel, numChannels, state = g_currentMission.foliageSystem:getDensityMapData(self.decoFoliageName)
		if mapId ~= nil then
			local filter1 = self.filter1
			local filter2 = self.filter2
			local filter3 = self.filter3
			self:setValue(mapId, startChannel, numChannels, state, filter1, filter2, filter3)
		end
	end
end
function MeadowCreationTask:start(immediate)
	local success = MeadowCreationTask:superClass().start(self)
	if not success then
		return false
	else
		if self.terrainGroundType ~= nil then
			local deformation = TerrainDeformation.new(g_terrainNode)
			deformation:enablePaintingMode()
			local polygon3dVertices = self.area:getVerticesAs3DCoordinates()
			local terrainBrushId = g_groundTypeManager:getTerrainLayerByType(self.terrainGroundType)
			deformation:addPolygonalArea(polygon3dVertices, terrainBrushId, false)
			self.deformation = deformation
			g_terrainDeformationQueue:queueJob(deformation, false, "onTerrainDeformationTaskFinished", self, nil)
		end
		return true
	end
end
function MeadowCreationTask:onTerrainDeformationTaskFinished(errorCode, displacementVolume, blockedObjectName, callbackArgs)
	Logging.devInfo("MeadowCreationTask:onTerrainDeformationTaskFinished errorCode=%d, displacementVolume=%.3f, blockedObjectName=%s", errorCode, displacementVolume, blockedObjectName)
	self.deformation:delete()
	self.deformation = nil
	self:tryFinish()
end
function MeadowCreationTask:tryFinish()
	if not self.finishedTerrainDetailUpdates then
		return
	end
	if self.deformation == nil then
		MeadowCreationTask:superClass().setFinished(self)
	end
end
function MeadowCreationTask:setFinished()
	self.finishedTerrainDetailUpdates = true
	self:tryFinish()
end
