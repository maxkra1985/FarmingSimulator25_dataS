-- Local values: MeadowCreationTask_mt
MeadowCreationTask = {}
local MeadowCreationTask_mt = Class(MeadowCreationTask, FieldUpdateTask)

function MeadowCreationTask.registerXMLPaths(schema, basePath)
	FieldUpdateTask.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".terrainGroundType#name", "Name of the terrain ground type", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".decoFoliage#name", "Name of the deco foliage", nil, false)
end

-- Upvalues: MeadowCreationTask_mt
-- Local values: self
function MeadowCreationTask.new(customMt)
	-- upvalues: (copy) MeadowCreationTask_mt
	local v5_ = MeadowCreationTask:superClass().new(customMt or MeadowCreationTask_mt)
	v5_.terrainGroundType = nil
	v5_.decoFoliageName = nil
	v5_.deformation = nil
	return v5_
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

-- Local values: terrainGroundType, decoFoliage
function MeadowCreationTask:loadFromXMLFile(xmlFile, key)
	local v12_ = xmlFile:getValue(key .. ".terrainGroundType#name")
	if v12_ ~= nil then
		self:setTerrainGroundType(v12_)
	end
	local v13_ = xmlFile:getValue(key .. ".decoFoliage#name")
	if v13_ ~= nil then
		self:setDecoFoliage(v13_)
	end
	return MeadowCreationTask:superClass().loadFromXMLFile(self, xmlFile, key)
end

function MeadowCreationTask:setDecoFoliage(decoFoliageName)
	if g_currentMission.foliageSystem:getIsDecoLayerDefined(decoFoliageName) then
		self.decoFoliageName = decoFoliageName
	else
		Logging.warning("MeadowCreationTask.setDecoFoliage: DecoFoliage \'%s\' not defined on current map ", decoFoliageName)
	end
end

-- Local values: layerId
function MeadowCreationTask:setTerrainGroundType(terrainGroundType)
	if g_groundTypeManager:getTerrainLayerByType(terrainGroundType) == nil then
		Logging.warning("MeadowCreationTask.setTerrainGroundType: Terrain Ground Type \'%s\' not supported by map", terrainGroundType)
	else
		self.terrainGroundType = terrainGroundType
	end
end

-- Local values: mapId, startChannel, numChannels, state, filter1, filter2, filter3
function MeadowCreationTask:prepare()
	MeadowCreationTask:superClass().prepare(self)
	if self.decoFoliageName ~= nil then
		local v19_, v20_, v21_, v22_ = g_currentMission.foliageSystem:getDensityMapData(self.decoFoliageName)
		if v19_ ~= nil then
			self:setValue(v19_, v20_, v21_, v22_, self.filter1, self.filter2, self.filter3)
		end
	end
end

-- Local values: success, deformation, polygon3dVertices, terrainBrushId
function MeadowCreationTask:start(immediate)
	if not MeadowCreationTask:superClass().start(self) then
		return false
	end
	if self.terrainGroundType ~= nil then
		local v24_ = TerrainDeformation.new(g_terrainNode)
		v24_:enablePaintingMode()
		v24_:addPolygonalArea(self.area:getVerticesAs3DCoordinates(), g_groundTypeManager:getTerrainLayerByType(self.terrainGroundType), false)
		self.deformation = v24_
		g_terrainDeformationQueue:queueJob(v24_, false, "onTerrainDeformationTaskFinished", self, nil)
	end
	return true
end

function MeadowCreationTask:onTerrainDeformationTaskFinished(errorCode, displacementVolume, blockedObjectName, callbackArgs)
	Logging.devInfo("MeadowCreationTask:onTerrainDeformationTaskFinished errorCode=%d, displacementVolume=%.3f, blockedObjectName=%s", errorCode, displacementVolume, blockedObjectName)
	self.deformation:delete()
	self.deformation = nil
	self:tryFinish()
end

function MeadowCreationTask:tryFinish()
	if self.finishedTerrainDetailUpdates then
		if self.deformation == nil then
			MeadowCreationTask:superClass().setFinished(self)
		end
	else
		return
	end
end

function MeadowCreationTask:setFinished()
	self.finishedTerrainDetailUpdates = true
	self:tryFinish()
end
