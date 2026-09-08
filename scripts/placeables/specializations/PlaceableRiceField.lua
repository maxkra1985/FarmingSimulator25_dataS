PlaceableRiceField = {}
PlaceableRiceField.MAX_NUM_FIELDS = 255
PlaceableRiceField.MAX_NUM_VERTICES = 127
PlaceableRiceField.MIN_VERTEX_DISTANCE = 5
PlaceableRiceField.MAX_VERTEX_DISTANCE = 300
PlaceableRiceField.MAX_EXTENT = 500
PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN = 5
PlaceableRiceField.COST_PER_DISPLACED_M3 = 3
PlaceableRiceField.COL_MESH_SIZE_OFFSET = 0.75
PlaceableRiceField.UNDERWATER_FOG_COLOR = {}
PlaceableRiceField.UNDERWATER_FOG_DEPTH = {}
PlaceableRiceField.BUILD_STATUS = {}
PlaceableRiceField.BUILD_STATUS.OK = 0
PlaceableRiceField.BUILD_STATUS.DEFORM_FAILED = 1
PlaceableRiceField.BUILD_STATUS.MESH_FAILED = 2
PlaceableRiceField.BUILD_STATUS.OVERLAP_FAILED = 3
PlaceableRiceField.BUILD_STATUS_LOCA_KEYS = {
	[PlaceableRiceField.BUILD_STATUS.DEFORM_FAILED] = "ui_construction_deformationFailed",
	[PlaceableRiceField.BUILD_STATUS.MESH_FAILED] = "warning_placeable_error_cannotBePlacedAtPosition",
	[PlaceableRiceField.BUILD_STATUS.OVERLAP_FAILED] = "ui_construction_overlapsWithObject"
}
PlaceableRiceField.FILL_DIRECTION = {}
PlaceableRiceField.FILL_DIRECTION.RISE = 1
PlaceableRiceField.FILL_DIRECTION.EMPTY = -1
PlaceableRiceField.WATER_LEVEL_NUM_BITS = 7
local v1_ = PlaceableRiceField
local v2_ = CollisionFlag.WATER
local v3_ = CollisionFlag.STATIC_OBJECT
local v4_ = CollisionFlag.TREE
local v5_ = CollisionFlag.BUILDING
local v6_ = CollisionFlag.VEHICLE
local v7_ = CollisionFlag.PLAYER
v1_.OVERLAP_MASK = bit32.bor(v2_, v3_, v4_, v5_, v6_, v7_)
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldStateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldEffectStateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldFieldEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldFieldAnswerEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldRemoveFieldEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableRiceFieldSetTargetHeightEvent.lua")
source("dataS/scripts/placeables/specializations/PlaceableRiceFieldActivatable.lua")

function PlaceableRiceField.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("RiceField")
	schema:register(XMLValueType.STRING, basePath .. ".riceField.area#groundType", "", "dirt")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.area#offsetFromRidge", "distance in m the ground type inside the rice field if offset from the ridge center", "-0.5")
	schema:register(XMLValueType.STRING, basePath .. ".riceField.ridge#groundType", "", "grass")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#height", "height of the ridge around the rice field in m", 0.35)
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#levelingWidth", "width of the ridge terrain leveling in m", 0.45)
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#paintWidth", "width of the painted area on the ridge around the rice field in m", 1)
	schema:register(XMLValueType.STRING, basePath .. ".riceField.ridge#foliageType", "foliage to place ontop of ridge")
	schema:register(XMLValueType.INT, basePath .. ".riceField.ridge#foliageGrowthState", "foliage growth state", 2)
	schema:register(XMLValueType.STRING, basePath .. ".riceField.ridge#foliageGrowthStateName", "foliage growth state name")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#foliageWidth", "foliage width", "paintWidth / 2")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.ridge#foliageOffsetFromRidge", "foliage offset", "0.5")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.water#maxLevel", "maximum height of the water", "80% or ridge height")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.water#fillDurationGameMinutes", "duration for fully filling field in game minutes")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".riceField.water#underwaterFogColor", "shader paramters for underwaterFogColor")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".riceField.water#underwaterFogDepth", "shader paramters for underwaterFogDepth")
	schema:register(XMLValueType.FILENAME, basePath .. ".riceField.pump#filename", "filepath to pump i3d file")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.filling#water", "node index path to filling water mesh")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.filling#splash", "node index path to filling water splash mesh")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.pump.filling#yOffset", "y offset of the splash above the water plane", 0.07)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.emptying#water", "node index path to emptying water mesh")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.pump.emptying#splash", "node index path to emptying water splash mesh")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".riceField.pump.sounds", "pump")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".riceField.pump.sounds", "water")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".riceField.playerTrigger#node", "node of the player trigger")
	schema:register(XMLValueType.STRING, basePath .. ".riceField.foliage#fruitTypes", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".riceField.foliage#offsetFromRidge", "")
	schema:setXMLSpecializationType()
end

function PlaceableRiceField.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("RiceField")
	schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?)#worldHeight", "world height/y level of the field")
	schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?)#waterHeight", "water height in meters")
	schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?)#waterHeightTarget", "water level target height in m relative to field ground")
	schema:register(XMLValueType.STRING, basePath .. ".fields.field(?)#initialFruit", "initial fruit for preplaced rice fields")
	schema:register(XMLValueType.INT, basePath .. ".fields.field(?)#initialFruitGrowthState", "initial fruit growth state index for preplaced rice fields")
	schema:register(XMLValueType.STRING, basePath .. ".fields.field(?).v(?)", "outline vertex x z position")
	schema:register(XMLValueType.INT, basePath .. ".fields.field(?).waterLevels(?)#period", "period index")
	schema:register(XMLValueType.FLOAT, basePath .. ".fields.field(?).waterLevels(?)#levelPerSqm", "water level for period")
	schema:setXMLSpecializationType()
end

function PlaceableRiceField.prerequisitesPresent(self)
	return true
end

function PlaceableRiceField.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onPumpI3DLoaded", PlaceableRiceField.onPumpI3DLoaded)
	SpecializationUtil.registerFunction(placeableType, "drawDebug", PlaceableRiceField.drawDebug)
	SpecializationUtil.registerFunction(placeableType, "getCanCreateNewField", PlaceableRiceField.getCanCreateNewField)
	SpecializationUtil.registerFunction(placeableType, "createNewField", PlaceableRiceField.createNewField)
	SpecializationUtil.registerFunction(placeableType, "removeFieldByNode", PlaceableRiceField.removeFieldByNode)
	SpecializationUtil.registerFunction(placeableType, "removeFieldByIndex", PlaceableRiceField.removeFieldByIndex)
	SpecializationUtil.registerFunction(placeableType, "deleteField", PlaceableRiceField.deleteField)
	SpecializationUtil.registerFunction(placeableType, "getFields", PlaceableRiceField.getFields)
	SpecializationUtil.registerFunction(placeableType, "getFieldByIndex", PlaceableRiceField.getFieldByIndex)
	SpecializationUtil.registerFunction(placeableType, "getFieldByNode", PlaceableRiceField.getFieldByNode)
	SpecializationUtil.registerFunction(placeableType, "getCanAddVertex", PlaceableRiceField.getCanAddVertex)
	SpecializationUtil.registerFunction(placeableType, "getCanFinish", PlaceableRiceField.getCanFinish)
	SpecializationUtil.registerFunction(placeableType, "onPolyhedronOverlap", PlaceableRiceField.onPolyhedronOverlap)
	SpecializationUtil.registerFunction(placeableType, "onFinishedGrowthPeriod", PlaceableRiceField.onFinishedGrowthPeriod)
	SpecializationUtil.registerFunction(placeableType, "getHasValidFields", PlaceableRiceField.getHasValidFields)
	SpecializationUtil.registerFunction(placeableType, "addVertex", PlaceableRiceField.addVertex)
	SpecializationUtil.registerFunction(placeableType, "removeLastVertex", PlaceableRiceField.removeLastVertex)
	SpecializationUtil.registerFunction(placeableType, "tryToFinishField", PlaceableRiceField.tryToFinishField)
	SpecializationUtil.registerFunction(placeableType, "finalizeNewField", PlaceableRiceField.finalizeNewField)
	SpecializationUtil.registerFunction(placeableType, "onRiceFieldAnswerEvent", PlaceableRiceField.onRiceFieldAnswerEvent)
	SpecializationUtil.registerFunction(placeableType, "buildMesh", PlaceableRiceField.buildMesh)
	SpecializationUtil.registerFunction(placeableType, "performTerrainDeformation", PlaceableRiceField.performTerrainDeformation)
	SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationFinished", PlaceableRiceField.onTerrainDeformationFinished)
	SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationFailed", PlaceableRiceField.onTerrainDeformationFailed)
	SpecializationUtil.registerFunction(placeableType, "onTerrainDeformationTaskFinished", PlaceableRiceField.onTerrainDeformationTaskFinished)
	SpecializationUtil.registerFunction(placeableType, "getFirstAndLastVertex", PlaceableRiceField.getFirstAndLastVertex)
	SpecializationUtil.registerFunction(placeableType, "getNumVertices", PlaceableRiceField.getNumVertices)
	SpecializationUtil.registerFunction(placeableType, "setWaterHeight", PlaceableRiceField.setWaterHeight)
	SpecializationUtil.registerFunction(placeableType, "setEffectVisibility", PlaceableRiceField.setEffectVisibility)
	SpecializationUtil.registerFunction(placeableType, "getWaterHeight", PlaceableRiceField.getWaterHeight)
	SpecializationUtil.registerFunction(placeableType, "setWaterHeightTarget", PlaceableRiceField.setWaterHeightTarget)
	SpecializationUtil.registerFunction(placeableType, "getWaterHeightTarget", PlaceableRiceField.getWaterHeightTarget)
	SpecializationUtil.registerFunction(placeableType, "getWaterFillLevel", PlaceableRiceField.getWaterFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getWaterFillLevelPerSqm", PlaceableRiceField.getWaterFillLevelPerSqm)
	SpecializationUtil.registerFunction(placeableType, "getFieldFillingState", PlaceableRiceField.getFieldFillingState)
	SpecializationUtil.registerFunction(placeableType, "getMaxWaterHeight", PlaceableRiceField.getMaxWaterHeight)
	SpecializationUtil.registerFunction(placeableType, "getArea", PlaceableRiceField.getArea)
	SpecializationUtil.registerFunction(placeableType, "getSupportedFruitTypes", PlaceableRiceField.getSupportedFruitTypes)
	SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableRiceField.playerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "renderEdges", PlaceableRiceField.renderEdges)
	SpecializationUtil.registerFunction(placeableType, "getRiceFieldState", PlaceableRiceField.getRiceFieldState)
	SpecializationUtil.registerFunction(placeableType, "onRiceFieldStatusResult", PlaceableRiceField.onRiceFieldStatusResult)
	SpecializationUtil.registerFunction(placeableType, "getConfirmDestruction", PlaceableRiceField.getConfirmDestruction)
end

function PlaceableRiceField.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "addToPhysics", PlaceableRiceField.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableRiceField.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getIsOnFarmland", PlaceableRiceField.getIsOnFarmland)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getFarmlandId", PlaceableRiceField.getFarmlandId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableRiceField.getDestructionMethod)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableRiceField.performNodeDestruction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableRiceField.previewNodeDestructionNodes)
end

function PlaceableRiceField.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onDirtyMaskCleared", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onUpdateTick", PlaceableRiceField)
	SpecializationUtil.registerEventListener(placeableType, "onPeriodChanged", PlaceableRiceField)
end
function PlaceableRiceField.initSpecialization()
	if g_isDevelopmentVersion then
		addConsoleCommand("gsRiceFieldWaterSetLevel", "Set rice field water level percentage", "consoleCommandSetWaterLevel", PlaceableRiceField)
		addConsoleCommand("gsRiceFieldWaterSetShaderParameters", "Set rice field water plane shader parameters", "consoleCommandsetWaterShaderParameters", PlaceableRiceField, "r; g; b; a; depthScale; refractionColorScale; getWaterDepthScale; inscatteringScale")
		addConsoleCommand("gsRiceFieldSetRice", "Set field rice state", "consoleCommandSetRiceState", PlaceableRiceField, "fruitTypeName; growthState; groundAngle")
		addConsoleCommand("gsRiceFieldCreateFromField", "Create a rice field from a field using the same outline", "consoleCommandCreateRiceFieldFromField", PlaceableRiceField, "fieldIndex")
	end
end
function PlaceableRiceField.terminateSpecialization()
	if g_isDevelopmentVersion then
		removeConsoleCommand("gsRiceFieldWaterSetLevel")
		removeConsoleCommand("gsRiceFieldWaterSetShaderParameters")
		removeConsoleCommand("gsRiceFieldSetRice")
		removeConsoleCommand("gsRiceFieldCreateFromField")
	end
end

-- Local values: spec, xmlFile, foliageTypeName, foliageGrowthState, foliageGrowthStateName, waterFillDurationGameMinutes, pumpFilename, args, fruitTypeNames
function PlaceableRiceField:onLoad(savegame)
	local v16_ = self.spec_riceField
	local v17_ = self.xmlFile
	v16_.fields = {}
	v16_.triggerToFieldIndex = {}
	v16_.fieldsToCheckForOverlap = {}
	v16_.nodesToCheckForOverlap = {}
	v16_.groundTypeInner = v17_:getValue("placeable.riceField.area#groundType")
	v16_.groundInnerOffsetFromRidge = v17_:getValue("placeable.riceField.area#offsetFromRidge", -0.5)
	v16_.groundTypeRidge = v17_:getValue("placeable.riceField.ridge#groundType")
	v16_.ridgeHeight = v17_:getValue("placeable.riceField.ridge#height", 0.35)
	v16_.levelingWidth = v17_:getValue("placeable.riceField.ridge#levelingWidth", 0.45)
	v16_.ridgePaintWidth = v17_:getValue("placeable.riceField.ridge#paintWidth", 1)
	local v18_ = v17_:getValue("placeable.riceField.ridge#foliageType")
	if v18_ ~= nil then
		v16_.ridgeFoliageType = g_fruitTypeManager:getFruitTypeByName(v18_)
		if v16_.ridgeFoliageType == nil then
			Logging.xmlWarning(v17_, "Foliage type \'%s\' does not exist!", v18_)
		else
			local v19_ = v17_:getValue("placeable.riceField.ridge#foliageGrowthStateName")
			local v20_
			if v19_ == nil then
				v20_ = nil
			else
				v20_ = v16_.ridgeFoliageType:getGrowthStateByName(v19_)
				if v20_ == nil then
					Logging.xmlWarning(v17_, "Foliage growthstate name \'%s\' does not exist for fruit type \'%s\'!", v19_, v18_)
				end
			end
			if v20_ == nil then
				v20_ = v17_:getValue("placeable.riceField.ridge#foliageGrowthStateName", 2)
			end
			v16_.ridgeFoliageGrowthState = v20_
			v16_.ridgeFoliageWidth = v17_:getValue("placeable.riceField.ridge#foliageWidth", v16_.ridgePaintWidth / 2)
			v16_.ridgeFoliageOffset = v17_:getValue("placeable.riceField.ridge#foliageOffsetFromRidge", 0.5)
		end
	end
	v16_.waterMaxLevel = v17_:getValue("placeable.riceField.water#maxLevel", v16_.ridgeHeight * 0.8)
	v16_.waterFillDurationMs = v17_:getValue("placeable.riceField.water#fillDurationGameMinutes", 60) * 60 * 1000
	v16_.underwaterFogColor = v17_:getValue("placeable.riceField.water#underwaterFogColor")
	v16_.underwaterFogDepth = v17_:getValue("placeable.riceField.water#underwaterFogDepth")
	v16_.playerTriggerNode = v17_:getValue("placeable.riceField.playerTrigger#node", nil, self.components, self.i3dMappings)
	local v21_ = v17_:getValue("placeable.riceField.pump#filename")
	if v21_ ~= nil then
		local v22_ = Utils.getFilename(v21_, self.baseDirectory)
		local v23_ = {
			["loadingTask"] = self:createLoadingTask(v16_),
			["xmlFile"] = v17_
		}
		v16_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v22_, false, false, self.onPumpI3DLoaded, self, v23_)
	end
	if self.isClient then
		v16_.samples = {}
		v16_.samples.pumpSound = g_soundManager:loadSampleFromXML(v17_, "placeable.riceField.pump.sounds", "pump", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v16_.samples.waterSound = g_soundManager:loadSampleFromXML(v17_, "placeable.riceField.pump.sounds", "water", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
	end
	local v24_ = v17_:getValue("placeable.riceField.foliage#fruitTypes", "RICELONGGRAIN RICE")
	v16_.fruitTypes = g_fruitTypeManager:getFruitTypesByNames(v24_)
	v16_.foliageOffsetFromRidge = v17_:getValue("placeable.riceField.foliage#offsetFromRidge", -1)
	if self.isServer then
		v16_.waterPlanesDirtyFlag = self:getNextDirtyFlag()
		v16_.fieldIndicesDirty = {}
		v16_.fieldsPendingTargetWaterLevel = {}
	end
	v16_.activatable = PlaceableRiceFieldActivatable.new(self)
	g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
end

-- Local values: spec, loadingTask, xmlFile
function PlaceableRiceField:onPumpI3DLoaded(i3dNode, failedReason, args)
	local v28_ = self.spec_riceField
	local v29_ = args.loadingTask
	local v30_ = args.xmlFile
	if i3dNode == 0 then
		self:finishLoadingTask(v29_)
		return false
	end
	v28_.pumpNode = i3dNode
	v28_.fillingWaterPath = v30_:getString("placeable.riceField.pump.filling#water")
	v28_.fillingSplashPath = v30_:getString("placeable.riceField.pump.filling#splash")
	v28_.fillingSplashYOffset = v30_:getValue("placeable.riceField.pump.filling#yOffset", 0.07)
	v28_.emptyingWaterPath = v30_:getString("placeable.riceField.pump.emptying#water")
	v28_.emptyingSplashPath = v30_:getString("placeable.riceField.pump.emptying#splash")
	self:finishLoadingTask(v29_)
	return true
end

-- Local values: spec, _, field
function PlaceableRiceField:onDelete()
	local v32_ = self.spec_riceField
	g_currentMission.activatableObjectsSystem:removeActivatable(v32_.activatable)
	g_messageCenter:unsubscribe(MessageType.FINISHED_GROWTH_PERIOD, self)
	g_messageCenter:unsubscribe(PlaceableRiceFieldFieldAnswerEvent, self)
	g_debugManager:removeGroup("PlaceableRiceField" .. tostring(self))
	if v32_.fields ~= nil then
		for _, v33_ in ipairs(v32_.fields) do
			self:deleteField(v33_)
		end
		v32_.fields = {}
	end
	if v32_.pumpNode ~= nil then
		delete(v32_.pumpNode)
		v32_.pumpNode = nil
	end
	if v32_.samples ~= nil then
		g_soundManager:deleteSamples(v32_.samples)
	end
	if v32_.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v32_.sharedLoadRequestId)
		v32_.sharedLoadRequestId = nil
	end
end

-- Local values: numFields, i, height, field, numVertices, i, isFilling, isEmptying
function PlaceableRiceField:onReadStream(streamId, connection)
	for v36_ = 1, streamReadUInt8(streamId) do
		local v37_ = self:createNewField((streamReadFloat32(streamId)))
		local v38_ = streamReadUInt16(streamId)
		v37_.polygon = Polygon2D.new(v38_)
		for _ = 1, v38_ do
			v37_.polygon:addPos(streamReadFloat32(streamId), streamReadFloat32(streamId))
		end
		v37_.waterHeight = streamReadFloat32(streamId)
		local v39_, v40_
		if streamReadBool(streamId) then
			v37_.waterHeightTarget = streamReadFloat32(streamId)
			v39_ = v37_.waterHeightTarget > v37_.waterHeight
			if v37_.waterHeightTarget < v37_.waterHeight then
				v40_ = true
			else
				v40_ = false
			end
		else
			v39_ = false
			v40_ = false
		end
		self:buildMesh(v37_)
		self:setEffectVisibility(v36_, v39_, v40_)
	end
end

-- Local values: spec, numFields, _, field, _, vertexComponent
function PlaceableRiceField:onWriteStream(streamId, connection)
	local v43_ = self.spec_riceField
	local v44_ = #v43_.fields
	streamWriteUInt8(streamId, v44_)
	for _, v45_ in ipairs(v43_.fields) do
		streamWriteFloat32(streamId, v45_.height)
		streamWriteUInt16(streamId, v45_.polygon:getNumVertices())
		for _, v46_ in ipairs(v45_.polygon:getVertices()) do
			streamWriteFloat32(streamId, v46_)
		end
		streamWriteFloat32(streamId, v45_.waterHeight)
		if streamWriteBool(streamId, v45_.waterHeightTarget ~= nil) then
			streamWriteFloat32(streamId, v45_.waterHeightTarget)
		end
	end
end

-- Local values: spec, fieldIndex, field, waterHeight, resetTargetHeight
function PlaceableRiceField:onReadUpdateStream(streamId, timestamp, connection)
	local v50_ = self.spec_riceField
	if connection:getIsServer() and streamReadBool(streamId) then
		for v51_, v52_ in ipairs(v50_.fields) do
			if streamReadBool(streamId) then
				self:setWaterHeight(v51_, (NetworkUtil.readCompressedRange(streamId, 0, v50_.waterMaxLevel, PlaceableRiceField.WATER_LEVEL_NUM_BITS)))
				if streamReadBool(streamId) then
					v52_.waterHeightTarget = nil
				end
			end
		end
	end
end

-- Local values: spec, fieldIndex, field
function PlaceableRiceField:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v57_ = self.spec_riceField
	if not connection:getIsServer() then
		local v58_ = streamWriteBool
		local v59_ = v57_.waterPlanesDirtyFlag
		if v58_(streamId, (bit32.btest(dirtyMask, v59_))) then
			for v60_, v61_ in ipairs(v57_.fields) do
				if streamWriteBool(streamId, v57_.fieldIndicesDirty[v60_] ~= nil) then
					NetworkUtil.writeCompressedRange(streamId, v61_.waterHeight, 0, v57_.waterMaxLevel, PlaceableRiceField.WATER_LEVEL_NUM_BITS)
					streamWriteBool(streamId, v61_.waterHeightTarget == nil)
				end
			end
		end
	end
end

-- Local values: spec, fieldIndex, field
function PlaceableRiceField:onDirtyMaskCleared()
	local v63_ = self.spec_riceField
	if next(v63_.fieldIndicesDirty) ~= nil then
		for v64_, _ in ipairs(v63_.fields) do
			v63_.fieldIndicesDirty[v64_] = nil
		end
	end
end

-- Local values: spec, _, field, x, _, z, changeFactor, fieldIndex, field, dir, heightDiff, newHeight
function PlaceableRiceField:onUpdateTick(dt)
	local v67_ = self.spec_riceField
	if g_currentMission.shallowWaterSimulation ~= nil then
		for _, v68_ in ipairs(v67_.fields) do
			if v68_.isFilling and math.random() > 0.6 then
				local v69_, _, v70_ = getWorldTranslation(v68_.fillingSplash)
				g_currentMission.shallowWaterSimulation:paintCircle(v69_, nil, v70_, 0.3, MathUtil.randomFloat(-1, 1), MathUtil.randomFloat(-1, 1))
			end
		end
	end
	if self.isServer then
		local v71_ = g_currentMission:getEffectiveTimeScale() * dt / v67_.waterFillDurationMs
		for v72_ in pairs(v67_.fieldsPendingTargetWaterLevel) do
			local v73_ = v67_.fields[v72_]
			if v73_ ~= nil then
				local v74_ = v67_.fieldsPendingTargetWaterLevel[v72_]
				if (v73_.waterHeight - v73_.waterHeightTarget) * v74_ >= 0 then
					v67_.fieldsPendingTargetWaterLevel[v72_] = nil
					v73_.waterHeightTarget = nil
					self:setEffectVisibility(v72_, false, false)
					v67_.fieldIndicesDirty[v72_] = true
					self:raiseDirtyFlags(v67_.waterPlanesDirtyFlag)
					self:raiseActive()
				else
					local v75_ = v73_.waterHeight + v74_ * v67_.waterMaxLevel * v71_
					local v76_
					if v74_ == PlaceableRiceField.FILL_DIRECTION.RISE then
						local v77_ = v73_.waterHeightTarget
						v76_ = math.min(v75_, v77_)
					else
						local v78_ = v73_.waterHeightTarget
						v76_ = math.max(v75_, v78_)
					end
					self:setWaterHeight(v72_, v76_)
				end
			end
		end
	end
end

function PlaceableRiceField.addToPhysics(self) end

-- Local values: spec, fieldIndex, field, x, y, z, text
function PlaceableRiceField:drawDebug()
	local v80_ = self.spec_riceField
	for v81_, v82_ in ipairs(v80_.fields) do
		local v83_, v84_, v85_ = getWorldTranslation(v82_.playerTriggerNode)
		if DebugUtil.isPositionInCameraRange(v83_, v84_, v85_, 10) then
			local v86_ = string.format("index %d\nwaterHeight %.3f\narea %d sqm\n", v81_, v82_.waterHeight, v82_.areaSqm)
			if v82_.waterHeightTarget ~= nil then
				v86_ = v86_ .. string.format("waterTarget %.3f", v82_.waterHeightTarget)
			end
			DebugText.renderAtPosition(v83_, v84_ + 2, v85_, v86_)
		end
	end
end

-- Local values: fieldIndex, fieldKey, height, field, waterHeightTarget, numVertexElements, _, periodKey, period, initialFruitName, initialFruitType
function PlaceableRiceField:loadFromXMLFile(xmlFile, key)
	for v90_, v91_ in xmlFile:iterator(key .. ".fields.field") do
		local v_u_92_ = self:createNewField((xmlFile:getValue(v91_ .. "#worldHeight")))
		v_u_92_.waterHeight = xmlFile:getValue(v91_ .. "#waterHeight") or 0
		local v93_ = xmlFile:getValue(v91_ .. "#waterHeightTarget")
		local v94_ = xmlFile:getNumOfElements(v91_ .. ".v")
		v_u_92_.polygon = Polygon2D.new(v94_)
		for _, v95_ in xmlFile:iterator(v91_ .. ".waterLevels") do
			local v96_ = xmlFile:getValue(v95_ .. "#period")
			v_u_92_.periodWaterLevelPerSqm[v96_] = xmlFile:getValue(v95_ .. "#levelPerSqm")
		end
		xmlFile:iterate(v91_ .. ".v", function(_, p97_)
			-- upvalues: (copy) xmlFile, (copy) v_u_92_
			local v98_ = xmlFile:getVector(p97_, nil, 2)
			v_u_92_.polygon:addPos(v98_[1], v98_[2])
		end)
		self:buildMesh(v_u_92_)
		if self.isServer and not g_currentMission.missionInfo.isValid then
			Logging.devInfo("perform initial deformation for rice field %q", key)
			local v99_ = xmlFile:getValue(v91_ .. "#initialFruit")
			if v99_ ~= nil then
				local v100_ = g_fruitTypeManager:getFruitTypeByName(v99_)
				if v100_ ~= nil then
					v_u_92_.initialFruitTypeIndex = v100_.index
					v_u_92_.initialFruitGrowthState = xmlFile:getValue(v91_ .. "#initialFruitGrowthState") or v100_:getMinHarvestingGrowthState()
					Logging.devInfo("initial fruit %q at growth state %d", v99_, v_u_92_.initialFruitGrowthState or -1)
				end
			end
			v_u_92_.deformationIsFree = true
			self:performTerrainDeformation(v_u_92_, callback)
		end
		if v93_ ~= nil then
			self:setWaterHeightTarget(v90_, v93_)
		end
	end
end

-- Local values: spec
function PlaceableRiceField:saveToXMLFile(xmlFile, key, usedModNames)
	local v104_ = self.spec_riceField
	xmlFile:setTable(key .. ".fields.field", v104_.fields, function(p105_, p106_, _)
		-- upvalues: (copy) xmlFile
		xmlFile:setValue(p105_ .. "#worldHeight", p106_.height)
		xmlFile:setValue(p105_ .. "#waterHeight", p106_.waterHeight)
		if p106_.waterHeightTarget ~= nil then
			xmlFile:setValue(p105_ .. "#waterHeightTarget", p106_.waterHeightTarget)
		end
		local v107_ = 0
		for v108_, v109_ in pairs(p106_.periodWaterLevelPerSqm) do
			xmlFile:setValue(string.format("%s.waterLevels(%d)#period", p105_, v107_), v108_)
			xmlFile:setValue(string.format("%s.waterLevels(%d)#levelPerSqm", p105_, v107_), v109_)
			v107_ = v107_ + 1
		end
		for v110_, v111_, v112_ in p106_.polygon:iteratorVertices() do
			xmlFile:setValue(string.format("%s.v(%d)", p105_, v110_ - 1), string.format("%.3f %.3f", v111_, v112_))
		end
	end)
end

function PlaceableRiceField:getDestructionMethod(superFunc)
	return Placeable.DESTRUCTION.PER_NODE
end

function PlaceableRiceField:getConfirmDestruction()
	return true
end

-- Local values: field
function PlaceableRiceField:previewNodeDestructionNodes(superFunc, node)
	local v115_ = self:getFieldByNode(node)
	if v115_ ~= nil then
		renderShapeOutline(v115_.mesh, false)
		I3DUtil.iterateRecursively(v115_.pumpNode, function(p116_)
			if getHasClassId(p116_, ClassIds.SHAPE) and (not getIsNonRenderable(p116_) and getVisibility(p116_)) then
				renderShapeOutline(p116_, false)
			end
		end)
	end
	return nil
end

-- Local values: didRemoveField, destroyPlaceable
function PlaceableRiceField:performNodeDestruction(superFunc, node)
	return self:removeFieldByNode(node), not self:getHasValidFields()
end

function PlaceableRiceField:collectPickObjects(superFunc, node, target) end

-- Local values: spec
function PlaceableRiceField:getCanCreateNewField()
	local v120_ = self.spec_riceField
	if v120_ == nil or v120_.fields == nil then
		return false
	else
		return #v120_.fields < PlaceableRiceField.MAX_NUM_FIELDS
	end
end

-- Local values: field
function PlaceableRiceField:createNewField(height)
	return {
		["node"] = nil,
		["height"] = height,
		["areaSqm"] = 0,
		["capacity"] = 0,
		["waterHeight"] = 0,
		["waterHeightTarget"] = nil,
		["periodWaterLevelPerSqm"] = {},
		["polygon"] = Polygon2D.new(),
		["polygonFoliage"] = nil,
		["mesh"] = nil,
		["mirrorMesh"] = nil,
		["colMesh"] = nil,
		["placementColMesh"] = nil,
		["pumpNode"] = nil,
		["playerTriggerNode"] = nil
	}
end

-- Local values: spec, fieldIndex, field
function PlaceableRiceField:removeFieldByNode(node)
	local v124_ = self.spec_riceField
	for v125_, v126_ in ipairs(v124_.fields) do
		if v126_.colMesh == node then
			g_client:getServerConnection():sendEvent(PlaceableRiceFieldRemoveFieldEvent.new(self, v125_))
			return true
		end
	end
	return false
end

-- Local values: spec, field
function PlaceableRiceField:removeFieldByIndex(index)
	local v129_ = self.spec_riceField
	local v130_ = v129_.fields[index]
	if v130_ == nil then
		return false
	end
	table.remove(v129_.fields, index)
	if self.isServer then
		v129_.fieldIndicesDirty[index] = nil
		v129_.fieldsPendingTargetWaterLevel[index] = nil
	end
	self:deleteField(v130_)
	return true
end

-- Local values: spec, enlargedPolygon, densityMapPolygon, fieldUpdateTask, deformWidthHalf, ridgeDeformation, edgeIndex, v1x, v1z, v2x, v2z, dx, dz, dxPerp, dzPerp, hx, hz, minX, maxX, minZ, maxZ
function PlaceableRiceField:deleteField(field)
	if field.mesh ~= nil then
		local v133_ = self.spec_riceField
		if g_currentMission.shallowWaterSimulation ~= nil then
			g_currentMission.shallowWaterSimulation:removeWaterPlane(field.mesh)
			g_currentMission.shallowWaterSimulation:removeAreaGeometry(field.mesh)
		end
		g_currentMission:removeNodeObject(field.colMesh)
		g_currentMission:removeNodeObject(field.placementColMesh)
		if field.pumpSound ~= nil then
			g_soundManager:deleteSample(field.pumpSound)
			field.pumpSound = nil
		end
		if field.waterSound ~= nil then
			g_soundManager:deleteSample(field.waterSound)
			field.waterSound = nil
		end
		v133_.triggerToFieldIndex[field.playerTriggerNode] = nil
		removeTrigger(field.playerTriggerNode)
		field.mesh = nil
		field.mirrorMesh = nil
		field.colMesh = nil
		field.placementColMesh = nil
		field.pumpNode = nil
		field.playerTriggerNode = nil
		field.fillingWater = nil
		field.emptyingWater = nil
		field.fillingSplash = nil
		field.emptyingSplash = nil
		delete(field.node)
		if g_server ~= nil and not g_currentMission.isExitingGame then
			if not self.isReloading then
				local v134_ = field.polygon:getOffsetPolygon(v133_.ridgePaintWidth)
				local v135_ = DensityMapPolygon.new()
				v135_:updateFromPolygon2D(v134_)
				local v136_ = FieldUpdateTask.new()
				v136_:setName("PlaceableRiceField deleteField()")
				v136_:setArea(v135_)
				v136_:setGroundType(FieldGroundType.NONE)
				v136_:setWaterLevel(0)
				v136_:setFieldType(FieldType.DEFAULT)
				v136_:setFruit(FruitType.UNKNOWN, 0)
				v136_:enqueue()
			end
			local v137_ = v133_.levelingWidth / 2
			local v138_ = TerrainDeformation.new(g_terrainNode)
			v138_:enableDeformationMode()
			v138_:setOutsideAreaConstraints(PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN * 1.1, 0.7853981633974483, 0.8726646259971648)
			for _, v139_, v140_, v141_, v142_ in field.polygon:iteratorEdges() do
				local v143_, v144_ = MathUtil.vector2Normalize(v141_ - v139_, v142_ - v140_)
				local v145_ = -v144_
				local v146_ = v139_ - v143_ * v137_ + v145_ * v137_
				local v147_ = v140_ - v144_ * v137_ + v143_ * v137_
				local v148_ = v141_ + v143_ * v137_ + v145_ * v137_
				local v149_ = v142_ + v144_ * v137_ + v143_ * v137_
				local v150_ = v148_ - v146_
				local v151_ = v149_ - v147_
				local v152_, v153_ = MathUtil.vector2SetLength(v151_, -v150_, v133_.levelingWidth)
				v138_:addArea(v146_, field.height, v147_, v150_, 0, v151_, v152_, 0, v153_, TerrainDeformation.NO_TERRAIN_BRUSH, false)
			end
			g_terrainDeformationQueue:queueJob(v138_, false)
			local v154_, v155_, v156_, v157_ = field.polygon:getBoundingBox()
			g_densityMapHeightManager:setCollisionMapAreaDirty(v154_, v156_, v155_, v157_, true)
		end
	end
end

-- Local values: spec
function PlaceableRiceField:getFields()
	return self.spec_riceField.fields
end

-- Local values: spec
function PlaceableRiceField:getFieldByIndex(fieldIndex)
	return self.spec_riceField.fields[fieldIndex]
end

-- Local values: spec, parent, _, field
function PlaceableRiceField:getFieldByNode(node)
	local v163_ = self.spec_riceField
	local v164_ = getParent(node)
	while v164_ ~= 0 and v164_ ~= self.rootNode do
		local v165_ = getParent(v164_)
		node = v164_
		v164_ = v165_
	end
	for _, v166_ in ipairs(v163_.fields) do
		if v166_.node == node then
			return v166_
		end
	end
	return nil
end

-- Local values: spec, _, field, _, vx, vz
function PlaceableRiceField:getIsOnFarmland(superFunc, farmlandId)
	local v169_ = self.spec_riceField
	for _, v170_ in ipairs(v169_.fields) do
		for _, v171_, v172_ in v170_.polygon:iteratorVertices() do
			if g_farmlandManager:getFarmlandIdAtWorldPosition(v171_, v172_) == farmlandId then
				return true
			end
		end
	end
	return false
end

-- Local values: spec, farmland, _, field, _, vx, vz, vertexFarmland
function PlaceableRiceField:getFarmlandId(superFunc)
	local v174_ = self.spec_riceField
	local v175_ = nil
	for _, v176_ in ipairs(v174_.fields) do
		for _, v177_, v178_ in v176_.polygon:iteratorVertices() do
			local v179_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v177_, v178_)
			if v175_ == nil or v179_ == v175_ then
				v175_ = v179_
			else
				Logging.warning("PlaceableRiceField:getFarmland(): placeable spans more than one farmland: %d and %d", v175_, v179_)
			end
		end
	end
	return v175_
end

-- Local values: numVertices, lastVertexX, lastVertexZ, distance, step, alpha, x, z, terrainHeight, minX, maxX, minZ, maxZ, index, x1, z1, x2, z2
function PlaceableRiceField:getCanAddVertex(field, newX, newZ)
	if field.polygon:getNumVertices() >= PlaceableRiceField.MAX_NUM_VERTICES then
		return false, "Maximum number of vertices reached"
	end
	if not g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self:getOwnerFarmId(), newX, newZ) then
		return false, g_i18n:getText("ui_construction_landIsNotOwned")
	end
	local v184_ = getTerrainHeightAtWorldPos(g_terrainNode, newX, 0, newZ) - field.height
	if math.abs(v184_) > PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN then
		return false, g_i18n:getText("ui_construction_heightDifferenceTooLarge")
	end
	local v185_ = field.polygon:getNumVertices()
	if v185_ >= 1 then
		local v186_, v187_ = field.polygon:getLastVertex()
		local v188_ = MathUtil.vector2Length(v186_ - newX, v187_ - newZ)
		if v188_ < PlaceableRiceField.MIN_VERTEX_DISTANCE then
			return false, g_i18n:getText("ui_construction_riceFieldCornerTooClose")
		end
		if PlaceableRiceField.MAX_VERTEX_DISTANCE < v188_ then
			return false, g_i18n:getText("ui_construction_riceFieldCornerTooFar")
		end
		if not g_farmlandManager:getIsOwnedByFarmAlongLine(self:getOwnerFarmId(), v186_, v187_, newX, newZ) then
			return false, g_i18n:getText("ui_construction_landIsNotOwned")
		end
		if g_densityMapHeightManager:getIsPlacementAreaBlocked(v186_, v187_, newX, newZ) then
			return false, g_i18n:getText("ui_construction_areaRestricted")
		end
		if v188_ ~= 0 then
			for v189_ = 0, 1, getTerrainHeightmapUnitSize(g_terrainNode) / v188_ do
				local v190_, v191_ = MathUtil.vector2Lerp(v186_, v187_, newX, newZ, v189_)
				local v192_ = getTerrainHeightAtWorldPos(g_terrainNode, v190_, 0, v191_) - field.height
				if math.abs(v192_) > PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN then
					return false, g_i18n:getText("ui_construction_heightDifferenceTooLarge")
				end
			end
		end
		if v185_ > 1 then
			local v193_ = math.huge
			local v194_ = -math.huge
			local v195_ = math.huge
			local v196_ = -math.huge
			for _, v197_, v198_, v199_, v200_ in field.polygon:iteratorEdges() do
				if MathUtil.vector2Length(v197_ - newX, v198_ - newZ) < PlaceableRiceField.MIN_VERTEX_DISTANCE then
					return false, g_i18n:getText("ui_construction_riceFieldCornerTooClose")
				end
				v193_ = math.min(v193_, v197_)
				v194_ = math.max(v194_, v197_)
				v195_ = math.min(v195_, v198_)
				v196_ = math.max(v196_, v198_)
				if MathUtil.vector2Length(v194_ - newX, v196_ - newZ) > PlaceableRiceField.MAX_EXTENT or MathUtil.vector2Length(v193_ - newX, v195_ - newZ) > PlaceableRiceField.MAX_EXTENT then
					return false, g_i18n:getText("ui_construction_riceFieldMaxSizeReached")
				end
				if MathUtil.getAreLineSegmentsIntersecting(v186_, v187_, newX, newZ, v197_, v198_, v199_, v200_, true) then
					return false, g_i18n:getText("ui_construction_riceFieldIntersect")
				end
				if MathUtil.getDistanceToLineSegment2D(v197_, v198_, v199_, v200_, newX, newZ) <= 0.1 then
					return false, g_i18n:getText("ui_construction_riceFieldIntersect")
				end
			end
		end
	end
	return true
end

-- Local values: firstVertexX, firstVertexZ, lastVertexX, lastVertexZ, index, x1, z1, x2, z2
function PlaceableRiceField:getCanFinish(field, perpendicularOnly)
	if field == nil then
		return false
	end
	if field.polygon == nil or field.polygon:getNumVertices() < 3 then
		return false
	end
	local v203_, v204_ = field.polygon:getVertex(1)
	local v205_, v206_ = field.polygon:getLastVertex()
	if perpendicularOnly and (v203_ ~= v205_ and v204_ ~= v206_) then
		return false
	end
	for _, v207_, v208_, v209_, v210_ in field.polygon:iteratorEdges(nil, 1) do
		if MathUtil.getAreLineSegmentsIntersecting(v203_, v204_, v205_, v206_, v207_, v208_, v209_, v210_, true) then
			return false
		end
	end
	return true
end

-- Local values: spec, convexHull, overlapBoxHalfHeight, polyhedronPoints, i, _, fieldToCheck, _, vertexToCheckX, vertexToCheckZ, _, nodeToCheck, minX, maxX, minY, maxY, minZ, maxZ, wx, wy, wz, aabbIntersecting
function PlaceableRiceField:tryToFinishField(field)
	local v213_ = self.spec_riceField
	local v214_ = field.polygon:getConvexHull()
	table.clear(v213_.fieldsToCheckForOverlap)
	table.clear(v213_.nodesToCheckForOverlap)
	local v215_ = {}
	for v216_ = 1, #v214_, 2 do
		v215_[#v215_ + 1] = v214_[v216_]
		v215_[#v215_ + 1] = field.height - 5
		v215_[#v215_ + 1] = v214_[v216_ + 1]
		v215_[#v215_ + 1] = v214_[v216_]
		v215_[#v215_ + 1] = field.height + 5
		v215_[#v215_ + 1] = v214_[v216_ + 1]
	end
	overlapConvexPolyhedron(v215_, "onPolyhedronOverlap", self, PlaceableRiceField.OVERLAP_MASK, true, true, true, true)
	for _, v217_ in ipairs(v213_.fieldsToCheckForOverlap) do
		for _, v218_, v219_ in v217_.polygon:iteratorVertices() do
			if field.polygon:getIsPosInside(v218_, v219_) then
				return false
			end
		end
	end
	for _, v220_ in ipairs(v213_.nodesToCheckForOverlap) do
		local v221_, v222_, v223_, v224_
		if getHasClassId(v220_, ClassIds.SHAPE) then
			local v225_, v226_
			v221_, v222_, v225_, v226_, v223_, v224_ = getRigidBodyAABB(v220_)
		else
			local v227_, _, v228_ = getWorldTranslation(v220_)
			v221_ = v227_ - 0.5
			v222_ = v227_ + 0.5
			v223_ = v228_ - 0.5
			v224_ = v228_ + 0.5
		end
		if field.polygon:getIsPosInside(v221_, v223_) or field.polygon:getIsPosInside(v221_, v224_) or (field.polygon:getIsPosInside(v222_, v223_) or field.polygon:getIsPosInside(v222_, v224_)) then
			DebugShapeOutline.new():createWithNode(v220_):addToManager(nil, 10000)
			return false
		end
	end
	table.clear(v213_.fieldsToCheckForOverlap)
	table.clear(v213_.nodesToCheckForOverlap)
	return true
end

-- Local values: spec, placeableRiceField, field
function PlaceableRiceField:onPolyhedronOverlap(node)
	if node ~= 0 then
		local v231_ = self.spec_riceField
		local v232_ = g_currentMission:getNodeObject(node)
		if v232_ ~= nil and v232_.getFieldByNode ~= nil then
			local v233_ = v232_:getFieldByNode(node)
			if v233_ ~= nil then
				local v234_ = v231_.fieldsToCheckForOverlap
				table.insert(v234_, v233_)
				Logging.devInfo("PlaceableRiceField:onPolyhedronOverlap fieldsToCheckForOverlap %s", I3DUtil.getNodePath(node))
				return
			end
		end
		local v235_ = v231_.nodesToCheckForOverlap
		table.insert(v235_, node)
		Logging.devInfo("PlaceableRiceField:onPolyhedronOverlap nodesToCheckForOverlap %s", I3DUtil.getNodePath(node))
	end
end

-- Local values: canAdd, errorMessage
function PlaceableRiceField:addVertex(field, x, z)
	local v240_, v241_ = self:getCanAddVertex(field, x, z)
	if not v240_ then
		return false, v241_
	end
	field.polygon:addPos(x, z)
	return true, nil
end

function PlaceableRiceField:removeLastVertex(field)
	field.polygon:removeVertex(field.polygon:getNumVertices())
end

function PlaceableRiceField:finalizeNewField(field, noEventSent, callback)
	if not (self.isServer or noEventSent) then
		g_client:getServerConnection():sendEvent(PlaceableRiceFieldFieldEvent.new(self, field))
		self.pendingCallback = callback
		g_messageCenter:subscribeOneshot(PlaceableRiceFieldFieldAnswerEvent, self.onRiceFieldAnswerEvent, self)
		return true
	end
	if not self:tryToFinishField(field) then
		Logging.devInfo("PlaceableRiceField:finalizeNewField OVERLAP_FAILED")
		callback(PlaceableRiceField.BUILD_STATUS.OVERLAP_FAILED)
		return false
	end
	if self:buildMesh(field) then
		if self.isServer then
			self:performTerrainDeformation(field, callback)
		end
		return true
	end
	Logging.devInfo("PlaceableRiceField:finalizeNewField MESH_FAILED")
	callback(PlaceableRiceField.BUILD_STATUS.MESH_FAILED)
	return false
end

function PlaceableRiceField:onRiceFieldAnswerEvent(statusCode)
	self.pendingCallback(statusCode)
	self.pendingCallback = nil
end

-- Local values: spec, enlargedPolygon, densityMapPolygon, fieldUpdateTask, densityMapPolygonInner, shrunkPolygon, fieldUpdateTaskInner, groundType, fruitType, densityMapPolygonFoliage, fieldUpdateTaskFoliage, foliagePolygon, ridgeWidthHalf, edgeIndex, v1x, v1z, v2x, v2z, ridgeFoliageTask, densityMapPolygonRidge, dx, dz, dxPerp, dzPerp, offsetX, offsetZ, minX, maxX, minZ, maxZ, displacementCost
function PlaceableRiceField:onTerrainDeformationFinished(field, volumeDisplaced)
	local v252_ = self.spec_riceField
	local v253_ = field.polygon:getOffsetPolygon(v252_.ridgePaintWidth)
	local v254_ = DensityMapPolygon.new()
	v254_:updateFromPolygon2D(v253_)
	local v255_ = FieldUpdateTask.new()
	v255_:setName("PlaceableRiceField prepareField")
	v255_:setArea(v254_)
	v255_:clearHeight()
	v255_:setWeedState(0)
	v255_:setStoneLevel(0)
	v255_:setLimeLevel(1)
	if field.initialFruitTypeIndex == nil then
		v255_:setFruit(FruitType.UNKNOWN, 0)
	end
	v255_:setSprayType(FieldSprayType.NONE)
	v255_:setGroundType(FieldGroundType.NONE)
	v255_:resetDisplacement()
	v255_:clearTireTracks()
	v255_:enqueue()
	local v256_ = DensityMapPolygon.new()
	v256_:updateFromPolygon2D((field.polygon:getOffsetPolygon(v252_.groundInnerOffsetFromRidge)))
	local v257_ = FieldUpdateTask.new()
	v257_:setName("PlaceableRiceField set ground")
	v257_:setArea(v256_)
	local v258_ = FieldGroundType.CULTIVATED
	if field.initialFruitTypeIndex ~= nil then
		local v259_ = g_fruitTypeManager:getFruitTypeByIndex(field.initialFruitTypeIndex)
		if v259_ ~= nil then
			v258_ = v259_:getGrowthStateGroundType(field.initialFruitGrowthState) or v258_
		end
	end
	v257_:setGroundType(v258_)
	v257_:setFieldType(FieldType.RICE)
	v257_:enqueue()
	if field.initialFruitTypeIndex ~= nil then
		local v260_ = DensityMapPolygon.new()
		v260_:updateFromPolygon2D(field.polygonFoliage)
		local v261_ = FieldUpdateTask.new()
		v261_:setName("PlaceableRiceField set foliage")
		v261_:setArea(v260_)
		v261_:setFruit(field.initialFruitTypeIndex, field.initialFruitGrowthState)
		v261_:enqueue()
	end
	if v252_.ridgeFoliageType ~= nil then
		local v262_ = field.polygon:getOffsetPolygon(v252_.ridgeFoliageOffset)
		local v263_ = v252_.ridgeFoliageWidth / 2
		for _, v264_, v265_, v266_, v267_ in v262_:iteratorEdges() do
			local v268_ = FieldUpdateTask.new()
			v268_:setName("PlaceableRiceField set ridge foliage")
			local v269_ = DensityMapPolygon.new()
			local v270_, v271_ = MathUtil.vector2Normalize(v266_ - v264_, v267_ - v265_)
			local v272_ = v263_ * -v271_
			local v273_ = v263_ * v270_
			v269_:addPolygonPoint(v264_ + v272_, v265_ + v273_)
			v269_:addPolygonPoint(v266_ + v272_, v267_ + v273_)
			v269_:addPolygonPoint(v266_ - v272_, v267_ - v273_)
			v269_:addPolygonPoint(v264_ - v272_, v265_ - v273_)
			v268_:setArea(v269_)
			v268_:setFruit(v252_.ridgeFoliageType.index, v252_.ridgeFoliageGrowthState)
			v268_:enqueue()
		end
	end
	local v274_, v275_, v276_, v277_ = field.polygon:getBoundingBox()
	g_densityMapHeightManager:setCollisionMapAreaDirty(v274_, v276_, v275_, v277_, true)
	g_server:broadcastEvent(PlaceableRiceFieldFieldEvent.new(self, field), false, nil, self.placeableRiceField)
	if field.deformationIsFree then
		field.deformationIsFree = nil
	else
		local v278_ = volumeDisplaced * PlaceableRiceField.COST_PER_DISPLACED_M3
		g_currentMission:addMoney(-v278_, self:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_BUY, true)
	end
	field.brushCallback(PlaceableRiceField.BUILD_STATUS.OK)
	field.brushCallback = nil
end

-- Local values: spec
function PlaceableRiceField:onTerrainDeformationFailed(field)
	local v281_ = self.spec_riceField
	table.removeElement(v281_.fields, field)
	self:deleteField(field)
	field.brushCallback(PlaceableRiceField.BUILD_STATUS.DEFORM_FAILED)
	field.brushCallback = nil
end

-- Local values: spec, offsetPolygon, waterplaneNode, waterplaneMirrorsNode, waterplaneColNode, placementColPlaneNode, x, _, z, r, g, b, a, depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale, waterSimMat, waterMirrorMat, fieldIndex, waterSoundLinkNode, x1, z1, x2, z2, cx, cz, wx, wy, wz, heightDiff, orientation, ry
function PlaceableRiceField:buildMesh(field)
	local v284_ = self.spec_riceField
	local v285_ = field.polygon:getOffsetPolygon(PlaceableRiceField.COL_MESH_SIZE_OFFSET)
	if v285_ == nil then
		return false
	end
	local v286_ = createPlaneShapeFrom2DContour("riceFieldVisualWaterPlane", field.polygon:getVertices(), false)
	if v286_ == 0 then
		return false
	end
	local v287_ = clone(v286_, false, false, false)
	setName(v287_, "riceFieldVisualWaterPlaneMirror")
	local v288_ = createPlaneShapeFrom2DContour("riceFieldWaterCol", field.polygon:getVertices(), true)
	if v288_ == 0 then
		return false
	end
	local v289_ = createPlaneShapeFrom2DContour("riceFieldPlacementCol", v285_:getVertices(), true)
	if v289_ == 0 then
		return false
	end
	removeFromPhysics(v288_)
	removeFromPhysics(v289_)
	field.node = createTransformGroup("riceField")
	link(self.rootNode, field.node)
	field.mesh = v286_
	field.mirrorMesh = v287_
	field.colMesh = v288_
	field.placementColMesh = v289_
	link(field.node, v286_)
	link(field.node, v287_)
	link(field.node, v288_)
	link(field.node, v289_)
	local v290_, _, v291_ = getTranslation(v289_)
	setTranslation(v289_, v290_, field.height - 1, v291_)
	setCollisionFilter(v289_, CollisionFlag.PLACEMENT_BLOCKING, 1)
	setIsNonRenderable(v289_, true)
	addToPhysics(v289_)
	local v292_, _, v293_ = getTranslation(v288_)
	setTranslation(v288_, v292_, field.height + v284_.waterMaxLevel, v293_)
	setCollisionFilter(v288_, CollisionFlag.WATER, 1)
	setIsNonRenderable(v288_, true)
	addToPhysics(v288_)
	setShapeReceiveShadowmap(v286_, true)
	setShapeCastShadowmap(v286_, false)
	local v294_ = v284_.underwaterFogColor or PlaceableRiceField.UNDERWATER_FOG_COLOR
	local v295_, v296_, v297_, v298_ = unpack(v294_)
	local v299_ = v284_.underwaterFogDepth or PlaceableRiceField.UNDERWATER_FOG_DEPTH
	local v300_, v301_, v302_, v303_ = unpack(v299_)
	local v304_ = g_materialManager:getBaseMaterialByName("riceFieldWaterSimulation")
	if v304_ == nil then
		Logging.error("Unable to retrieve material \'riceFieldWaterSimulation\' for rice field water plane")
	else
		setMaterial(v286_, v304_, 0)
		setShaderParameter(v286_, "underwaterFogColor", v295_, v296_, v297_, v298_, false)
		setShaderParameter(v286_, "underwaterFogDepth", v300_, v301_, v302_, v303_, false)
	end
	setShapeReceiveShadowmap(v287_, true)
	setShapeCastShadowmap(v287_, false)
	local v305_ = g_materialManager:getBaseMaterialByName("riceFieldWaterInMirror")
	if v305_ == nil then
		Logging.error("Unable to retrieve material \'riceFieldWaterInMirror\' for rice field water plane")
	else
		setMaterial(v287_, v305_, 0)
		setShaderParameter(v286_, "underwaterFogColor", v295_, v296_, v297_, v298_)
		setShaderParameter(v286_, "underwaterFogDepth", v300_, v301_, v302_, v303_, false)
		setObjectMask(v287_, ObjectMask.SHAPE_VIS_MIRROR_ONLY)
	end
	field.polygonFoliage = field.polygon:getOffsetPolygon(v284_.foliageOffsetFromRidge)
	field.areaSqm = field.polygon:getArea()
	field.capacity = field.areaSqm * 1000 * v284_.waterMaxLevel
	local v306_ = v284_.fields
	table.insert(v306_, field)
	local v307_ = #v284_.fields
	self:setWaterHeight(v307_, field.waterHeight, true)
	if g_currentMission.shallowWaterSimulation ~= nil then
		g_currentMission.shallowWaterSimulation:addWaterPlane(field.mesh)
		g_currentMission.shallowWaterSimulation:addAreaGeometry(field.mesh)
	end
	g_currentMission:addNodeObject(v288_, self)
	g_currentMission:addNodeObject(v289_, self)
	field.pumpNode = clone(v284_.pumpNode, false, false, false)
	link(field.node, field.pumpNode)
	field.fillingWater = I3DUtil.indexToObject(field.pumpNode, v284_.fillingWaterPath)
	field.fillingSplash = I3DUtil.indexToObject(field.pumpNode, v284_.fillingSplashPath)
	field.emptyingWater = I3DUtil.indexToObject(field.pumpNode, v284_.emptyingWaterPath)
	field.emptyingSplash = I3DUtil.indexToObject(field.pumpNode, v284_.emptyingSplashPath)
	if v284_.samples ~= nil then
		if v284_.samples.pumpSound ~= nil then
			field.pumpSound = g_soundManager:cloneSample(v284_.samples.pumpSound, field.pumpNode)
		end
		if v284_.samples.waterSound ~= nil then
			local v308_ = createTransformGroup("riceFieldWaterSoundNode")
			link(field.pumpNode, v308_)
			field.waterSoundLinkNode = v308_
			field.waterSound = g_soundManager:cloneSample(v284_.samples.waterSound, field.waterSoundLinkNode)
		end
	end
	local v309_, v310_, v311_, v312_ = field.polygon:getEdge(1)
	local v313_ = (v309_ + v311_) / 2
	local v314_ = (v310_ + v312_) / 2
	setWorldTranslation(field.pumpNode, v313_, field.height, v314_)
	local v315_, v316_, v317_ = getWorldTranslation(field.emptyingSplash)
	local v318_ = getTerrainHeightAtWorldPos(g_terrainNode, v315_, 0, v317_) - v316_
	if math.abs(v318_) < 0.5 then
		setWorldTranslation(field.emptyingSplash, v315_, v316_ + 0.07, v317_)
	else
		delete(field.emptyingSplash)
		field.emptyingSplash = createTransformGroup("riceFieldEmptyingSplashDummy")
		link(field.pumpNode, field.emptyingSplash)
	end
	local v319_ = field.polygon:getCurveOrientation()
	local v320_ = -1.5707963267948966 + MathUtil.getYRotationFromDirection(v311_ - v309_, v312_ - v310_) + (v319_ == -1 and 3.141592653589793 or 0)
	setRotation(field.pumpNode, 0, v320_, 0)
	addToPhysics(field.pumpNode)
	self:setEffectVisibility(v307_, false, false)
	field.playerTriggerNode = clone(v284_.playerTriggerNode, false, false, false)
	link(field.node, field.playerTriggerNode)
	setWorldTranslation(field.playerTriggerNode, v313_, field.height, v314_)
	setRotation(field.playerTriggerNode, 0, v320_, 0)
	addToPhysics(field.playerTriggerNode)
	addTrigger(field.playerTriggerNode, "playerTriggerCallback", self)
	v284_.triggerToFieldIndex[field.playerTriggerNode] = v307_
	return true
end

-- Local values: spec, polygon3dVertices, terrainBrushId, deformWidthHalf, edgeIndex, v1x, v1z, v2x, v2z, dx, dz, dxPerp, dzPerp, hx, hz, ridgeWidthHalf, edgeIndex, v1x, v1z, v2x, v2z, dx, dz, dxPerp, dzPerp, hx, hz
function PlaceableRiceField:performTerrainDeformation(field, callback)
	local v324_ = self.spec_riceField
	field.displacedVolume = 0
	field.areaDeformation = TerrainDeformation.new(g_terrainNode)
	local v325_ = field.polygon:getVerticesAs3DCoordinates(field.height + 0.02)
	field.brushCallback = callback or function() end
	local v326_ = g_groundTypeManager:getTerrainLayerByType(v324_.groundTypeInner)
	field.areaDeformation:setOutsideAreaConstraints(PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN * 1.1, 0.7853981633974483, 0.8726646259971648)
	field.areaDeformation:addPolygonalArea(v325_, v326_, false)
	field.deformQueue = 1
	field.areaDeformationJobId = g_terrainDeformationQueue:queueJob(field.areaDeformation, false, "onTerrainDeformationTaskFinished", self, field)
	local v327_ = v324_.levelingWidth / 2
	field.ridgeDeformation = TerrainDeformation.new(g_terrainNode)
	field.ridgeDeformation:enableDeformationMode()
	field.ridgeDeformation:setOutsideAreaConstraints(PlaceableRiceField.MAX_HEIGHT_DIFF_TO_TERRAIN * 1.1, 0.7853981633974483, 0.8726646259971648)
	for _, v328_, v329_, v330_, v331_ in field.polygon:iteratorEdges() do
		local v332_, v333_ = MathUtil.vector2Normalize(v330_ - v328_, v331_ - v329_)
		local v334_ = -v333_
		local v335_ = v328_ - v332_ * v327_ + v334_ * v327_
		local v336_ = v329_ - v333_ * v327_ + v332_ * v327_
		local v337_ = v330_ + v332_ * v327_ + v334_ * v327_
		local v338_ = v331_ + v333_ * v327_ + v332_ * v327_
		local v339_ = v337_ - v335_
		local v340_ = v338_ - v336_
		local v341_, v342_ = MathUtil.vector2SetLength(v340_, -v339_, v324_.levelingWidth)
		field.ridgeDeformation:addArea(v335_, field.height + v324_.ridgeHeight, v336_, v339_, 0, v340_, v341_, 0, v342_, v326_, false)
	end
	field.deformQueue = field.deformQueue + 1
	field.ridgeDeformationJobId = g_terrainDeformationQueue:queueJob(field.ridgeDeformation, false, "onTerrainDeformationTaskFinished", self, field)
	local v343_ = g_groundTypeManager:getTerrainLayerByType(v324_.groundTypeRidge)
	if v343_ ~= nil then
		field.ridgeDeformationPaint = TerrainDeformation.new(g_terrainNode)
		field.ridgeDeformationPaint:enablePaintingMode()
		local v344_ = v324_.ridgePaintWidth / 2
		for _, v345_, v346_, v347_, v348_ in field.polygon:iteratorEdges() do
			local v349_, v350_ = MathUtil.vector2Normalize(v347_ - v345_, v348_ - v346_)
			local v351_ = -v350_
			local v352_ = v345_ - v349_ * v344_ + v351_ * v344_
			local v353_ = v346_ - v350_ * v344_ + v349_ * v344_
			local v354_ = v347_ + v349_ * v344_ + v351_ * v344_
			local v355_ = v348_ + v350_ * v344_ + v349_ * v344_
			local v356_ = v354_ - v352_
			local v357_ = v355_ - v353_
			local v358_, v359_ = MathUtil.vector2SetLength(v357_, -v356_, v324_.ridgePaintWidth)
			field.ridgeDeformationPaint:addArea(v352_, field.height + v324_.ridgeHeight, v353_, v356_, 0, v357_, v358_, 0, v359_, v343_, false)
		end
		field.deformQueue = field.deformQueue + 1
		field.ridgePaintJobId = g_terrainDeformationQueue:queueJob(field.ridgeDeformationPaint, false, "onTerrainDeformationTaskFinished", self, field)
	end
end

-- Local values: field, displavedVolume
function PlaceableRiceField:onTerrainDeformationTaskFinished(errorCode, displacementVolume, blockedObjectName, callbackArgs)
	Logging.devInfo("PlaceableRiceField:onTerrainDeformationFinished errorCode=%d, displacementVolume=%.3f, blockedObjectName=%s", errorCode, displacementVolume, blockedObjectName)
	if errorCode == TerrainDeformation.STATE_SUCCESS then
		callbackArgs.displacedVolume = callbackArgs.displacedVolume + displacementVolume
		callbackArgs.deformQueue = callbackArgs.deformQueue - 1
		if callbackArgs.deformQueue < 0 then
			Logging.error("queue count broken")
		end
		if callbackArgs.deformQueue == 0 then
			callbackArgs.areaDeformation:delete()
			callbackArgs.areaDeformation = nil
			callbackArgs.ridgeDeformationPaint:delete()
			callbackArgs.ridgeDeformationPaint = nil
			callbackArgs.ridgeDeformation:delete()
			callbackArgs.ridgeDeformation = nil
			local v365_ = callbackArgs.displacedVolume
			callbackArgs.displacedVolume = nil
			self:onTerrainDeformationFinished(callbackArgs, v365_)
		end
	elseif callbackArgs ~= nil then
		g_terrainDeformationQueue:cancelJob(callbackArgs.areaDeformationJobId)
		g_terrainDeformationQueue:cancelJob(callbackArgs.ridgeDeformationJobId)
		g_terrainDeformationQueue:cancelJob(callbackArgs.ridgePaintJobId)
		if callbackArgs.areaDeformation then
			callbackArgs.areaDeformation:delete()
			callbackArgs.areaDeformation = nil
			callbackArgs.areaDeformationJobId = nil
		end
		if callbackArgs.ridgeDeformationPaint then
			callbackArgs.ridgeDeformationPaint:delete()
			callbackArgs.ridgeDeformationPaint = nil
			callbackArgs.ridgePaintJobId = nil
		end
		if callbackArgs.ridgeDeformation then
			callbackArgs.ridgeDeformation:delete()
			callbackArgs.ridgeDeformation = nil
			callbackArgs.ridgeDeformationJobId = nil
		end
		callbackArgs.deformQueue = nil
		self:onTerrainDeformationFailed(callbackArgs)
	end
end

-- Local values: spec, prevPeriod, fieldIndex, field
function PlaceableRiceField:onPeriodChanged(period)
	local v368_ = self.spec_riceField
	if v368_.fields ~= nil then
		local v369_ = period - 1
		local v370_ = v369_ == 0 and 12 or v369_
		for v371_, v372_ in ipairs(v368_.fields) do
			v372_.periodWaterLevelPerSqm[v370_] = self:getWaterFillLevelPerSqm(v371_)
			self:setWaterHeight(v371_, -v368_.waterMaxLevel * 0.5)
		end
	end
end

-- Local values: spec, perlinSeed, perlinFilter, fieldIndex, field, waterFillLevelPerSqm, densityMapPolygonFoliage, riceFieldUpdateTask
function PlaceableRiceField:onFinishedGrowthPeriod(period)
	local v375_ = self.spec_riceField
	if v375_.fields ~= nil then
		local v376_ = PerlinNoiseFilter.new(v375_.fruitTypes[1].terrainDataPlaneId, 11, 1, 0.5, nil)
		for _, v377_ in ipairs(v375_.fields) do
			local v378_ = v377_.periodWaterLevelPerSqm[period]
			v377_.periodWaterLevelPerSqm[period] = nil
			if v378_ ~= nil then
				local v379_ = DensityMapPolygon.new()
				v379_:updateFromPolygon2D(v377_.polygonFoliage)
				local v380_ = RiceFieldUpdateTask.new()
				v380_:setArea(v379_)
				v380_:performPerlinNoiseDestruction(v375_.fruitTypes, v378_, v376_)
				v380_:enqueue()
			end
		end
	end
end

-- Local values: spec, _, field
function PlaceableRiceField:getHasValidFields()
	local v382_ = self.spec_riceField
	for _, v383_ in ipairs(v382_.fields) do
		if v383_.polygon:getNumVertices() >= 3 then
			return true
		end
	end
	return false
end

-- Local values: numVerts, v1x, v1z, v2x, v2z
function PlaceableRiceField:getFirstAndLastVertex(field)
	if field.polygon == nil then
		return nil
	else
		local v385_ = field.polygon:getNumVertices()
		if v385_ > 1 then
			local v386_, v387_ = field.polygon:getVertex(1)
			local v388_, v389_ = field.polygon:getVertex(v385_)
			return v386_, v387_, v388_, v389_
		elseif v385_ == 1 then
			return field.polygon:getVertex(1)
		else
			return nil
		end
	end
end

function PlaceableRiceField:getNumVertices(field)
	return field.polygon == nil and 0 or field.polygon:getNumVertices()
end

-- Local values: spec, field, abswaterFillLevel, wx, _wy, wz, visible, densityMapPolygonFoliage, fieldUpdateTaskInner
function PlaceableRiceField:setWaterHeight(fieldIndex, height, skipSetDirty)
	local v395_ = self.spec_riceField
	local v396_ = self:getFieldByIndex(fieldIndex)
	if v396_ ~= nil then
		local v397_ = v395_.waterMaxLevel
		v396_.waterHeight = math.clamp(height, 0, v397_)
		local v398_ = v396_.height + v396_.waterHeight
		local v399_, _, v400_ = getWorldTranslation(v396_.mesh)
		setWorldTranslation(v396_.mesh, v399_, v398_, v400_)
		setWorldTranslation(v396_.mirrorMesh, v399_, v398_, v400_)
		setShaderParameter(v396_.mesh, "waterLevelPercentage", height / v395_.waterMaxLevel)
		if v396_.fillingSplash ~= nil then
			local v401_, _, v402_ = getWorldTranslation(v396_.fillingSplash)
			setWorldTranslation(v396_.fillingSplash, v401_, v398_ + v395_.fillingSplashYOffset, v402_)
		end
		local v403_ = v396_.waterHeight > 0
		if getVisibility(v396_.mesh) ~= v403_ then
			setVisibility(v396_.mesh, v403_)
			setVisibility(v396_.mirrorMesh, v403_)
			if g_server ~= nil then
				local v404_ = DensityMapPolygon.new()
				v404_:updateFromPolygon2D(v396_.polygon)
				local v405_ = FieldUpdateTask.new()
				v405_:setName("PlaceableRiceField set water level")
				v405_:setArea(v404_)
				v405_:setWaterLevel(v403_ and 1 or 0)
				v405_:enqueue()
			end
			if v403_ then
				setCollisionFilterGroup(v396_.colMesh, CollisionFlag.WATER)
			else
				setCollisionFilterGroup(v396_.colMesh, CollisionFlag.PLACEMENT_BLOCKING)
			end
		end
		if self.isServer and not skipSetDirty then
			v395_.fieldIndicesDirty[fieldIndex] = true
			self:raiseDirtyFlags(v395_.waterPlanesDirtyFlag)
			self:raiseActive()
		end
		return v396_.waterHeight
	end
	Logging.error("unable to retrieve field for index %q", fieldIndex)
	printCallstack()
end

-- Local values: field
function PlaceableRiceField:setEffectVisibility(fieldIndex, isFilling, isEmptying)
	local v410_ = self:getFieldByIndex(fieldIndex)
	if v410_ ~= nil then
		v410_.isFilling = isFilling
		v410_.isEmptying = isEmptying
		setVisibility(v410_.fillingWater, isFilling)
		setVisibility(v410_.fillingSplash, isFilling)
		setVisibility(v410_.emptyingWater, isEmptying)
		setVisibility(v410_.emptyingSplash, isEmptying)
		if isFilling or isEmptying then
			setWorldTranslation(v410_.waterSoundLinkNode, getWorldTranslation(isFilling and v410_.fillingSplash or v410_.emptyingSplash))
			g_soundManager:playSample(v410_.pumpSound)
			g_soundManager:playSample(v410_.waterSound)
		else
			g_soundManager:stopSample(v410_.pumpSound)
			g_soundManager:stopSample(v410_.waterSound)
		end
		if g_server ~= nil then
			g_server:broadcastEvent(PlaceableRiceFieldEffectStateEvent.new(self, fieldIndex, isFilling, isEmptying), false)
		end
	end
end

-- Local values: field, spec, clampedHeight, waterHeight, isFilling
function PlaceableRiceField:setWaterHeightTarget(fieldIndex, targetHeight, noEventSent)
	local v415_ = self:getFieldByIndex(fieldIndex)
	if v415_ == nil then
		return
	else
		local v416_ = self.spec_riceField
		local v417_ = v416_.waterMaxLevel
		local v418_ = math.clamp(targetHeight, 0, v417_)
		v415_.waterHeightTarget = v418_
		if self.isServer then
			local v419_ = self:getWaterHeight(fieldIndex) < v418_
			v416_.fieldsPendingTargetWaterLevel[fieldIndex] = v419_ and PlaceableRiceField.FILL_DIRECTION.RISE or PlaceableRiceField.FILL_DIRECTION.EMPTY
			self:setEffectVisibility(fieldIndex, v419_, not v419_)
			if not noEventSent then
				g_server:broadcastEvent(PlaceableRiceFieldSetTargetHeightEvent.new(self, fieldIndex, v418_))
			end
			self:raiseActive()
		elseif not noEventSent then
			g_client:getServerConnection():sendEvent(PlaceableRiceFieldSetTargetHeightEvent.new(self, fieldIndex, v418_))
		end
	end
end

-- Local values: field
function PlaceableRiceField:getWaterHeightTarget(fieldIndex)
	local v422_ = self:getFieldByIndex(fieldIndex)
	if v422_ == nil then
		return nil
	else
		return v422_.waterHeightTarget
	end
end

-- Local values: field
function PlaceableRiceField:getWaterFillLevel(fieldIndex)
	local v425_ = self:getFieldByIndex(fieldIndex)
	if v425_ == nil then
		return nil
	else
		return v425_.waterHeight * v425_.areaSqm * 1000
	end
end

-- Local values: field
function PlaceableRiceField:getWaterHeight(fieldIndex)
	local v428_ = self:getFieldByIndex(fieldIndex)
	if v428_ == nil then
		return nil
	else
		return v428_.waterHeight
	end
end

-- Local values: field
function PlaceableRiceField:getWaterFillLevelPerSqm(fieldIndex)
	local v431_ = self:getFieldByIndex(fieldIndex)
	if v431_ == nil then
		return nil
	else
		return v431_.waterHeight * 1000
	end
end

-- Local values: spec
function PlaceableRiceField:getFieldFillingState(fieldIndex)
	local v434_ = self.spec_riceField
	if v434_.fieldsPendingTargetWaterLevel == nil then
		return nil
	else
		return v434_.fieldsPendingTargetWaterLevel[fieldIndex]
	end
end

-- Local values: spec
function PlaceableRiceField:getMaxWaterHeight()
	return self.spec_riceField.waterMaxLevel
end

-- Local values: field
function PlaceableRiceField:getArea(fieldIndex)
	local v438_ = self:getFieldByIndex(fieldIndex)
	if v438_ == nil then
		return nil
	else
		return v438_.areaSqm
	end
end

-- Local values: spec
function PlaceableRiceField:getSupportedFruitTypes()
	return self.spec_riceField.fruitTypes
end

-- Local values: player, spec, fieldIndex
function PlaceableRiceField:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v445_ = g_localPlayer
	if v445_ ~= nil and otherId == v445_.rootNode then
		local v446_ = self.spec_riceField
		local v447_ = v446_.triggerToFieldIndex[triggerId]
		if v447_ == nil then
			return
		end
		if onEnter then
			v446_.activatable:setRiceFieldIndex(v447_)
			g_currentMission.activatableObjectsSystem:addActivatable(v446_.activatable)
			return
		end
		if onLeave then
			v446_.activatable:setRiceFieldIndex(nil)
			g_currentMission.activatableObjectsSystem:removeActivatable(v446_.activatable)
		end
	end
end

-- Local values: color, minX, maxX, minZ, maxZ, area
function PlaceableRiceField:renderEdges(field)
	local v449_ = DebugUtil.tableToColor(field)
	field.polygon:renderEdges(field.height, v449_, false, true, true)
	local v450_, v451_, v452_, v453_ = field.polygon:getBoundingBox()
	local v454_ = field.polygon:getArea()
	if v454_ > 0 then
		Utils.renderTextAtWorldPosition((v450_ + v451_) / 2, field.height, (v452_ + v453_) / 2, string.format("%dsqm", v454_), nil, nil, v449_:unpack())
	end
end

-- Local values: field, infoTask, densityMapPolygon
function PlaceableRiceField:getRiceFieldState(fieldIndex, callback, callbackTarget)
	local v459_ = self:getFieldByIndex(fieldIndex)
	local v460_ = FieldGetInfoTask.new()
	local v461_ = DensityMapPolygon.new()
	v461_:updateFromPolygon2D(v459_.polygon)
	v460_:setArea(v461_)
	v460_:setFruitTypes(self:getSupportedFruitTypes())
	v460_:setCallback(self.onRiceFieldStatusResult, self, {
		["callback"] = callback,
		["callbackTarget"] = callbackTarget
	})
	v460_:enqueue()
end

-- Local values: labelMaxNumPixels, maxFruitPixels, pixelThreshold, label, numPixels, fruitTypeName, stageIndex
function PlaceableRiceField:onRiceFieldStatusResult(ftGrowthStatePixels, totalTouchedPixels, callbackArgs)
	local v465_ = totalTouchedPixels * 0.1
	local v466_ = 0
	local v467_ = nil
	for v468_, v469_ in pairs(ftGrowthStatePixels) do
		if v465_ < v469_ and v466_ < v469_ then
			v467_ = v468_
			v466_ = v469_
		end
	end
	if v467_ == nil then
		callbackArgs.callback(callbackArgs.callbackTarget, FruitType.UNKNOWN, 0)
	else
		local v470_ = string.split
		local v471_, v472_ = unpack(v470_(v467_, "|"))
		callbackArgs.callback(callbackArgs.callbackTarget, g_fruitTypeManager:getFruitTypeIndexByName(v471_), (tonumber(v472_)))
	end
end

-- Local values: waterPlane, object, field
function PlaceableRiceField.getRiceFieldAtPosition(x, y, z)
	local v476_ = RaycastUtil.raycastClosest(x, y + 1, z, 0, -1, 0, 10, CollisionFlag.WATER + CollisionFlag.PLACEMENT_BLOCKING)
	if v476_ == nil then
		return "Error: no water plane found.\nMake sure to be standing inside the a field"
	else
		local v477_ = g_currentMission.nodeToObject[v476_]
		if v477_ == nil or not (v477_:isa(Placeable) and SpecializationUtil.hasSpecialization(PlaceableRiceField, v477_.self)) then
			return "Error: no rice field placeable found.\nMake sure to be standing inside a rice field"
		else
			local v478_ = v477_:getFieldByNode(v476_)
			if v478_ == nil then
				return string.format("Error: no field found for water plane %q (%d)", getName(v476_), v476_)
			else
				return nil, v477_, v476_, v478_
			end
		end
	end
end

-- Local values: x, y, z, errorMsg, object, _waterPlane, field, spec, fieldIndex
function PlaceableRiceField.consoleCommandSetWaterLevel(_, waterFillLevelPercentage)
	local v480_ = tonumber(waterFillLevelPercentage)
	if v480_ == nil or (v480_ < 0 or v480_ > 100) then
		printError("Error: no valid water level given")
		return "Usage: gsRiceFieldWaterSetLevel percentage[0..100]"
	end
	local v481_, v482_, v483_ = g_localPlayer:getPosition()
	local v484_, v485_, _, v486_ = PlaceableRiceField.getRiceFieldAtPosition(v481_, v482_, v483_)
	if v484_ == nil then
		local v487_ = v485_.spec_riceField
		v485_:setWaterHeight(table.find(v485_:getFields(), v486_), v487_.waterMaxLevel * (v480_ / 100))
		return string.format("Set water level to %.3fm (%d%%)", v486_.waterHeight, v480_)
	end
	printError(v484_)
end

-- Local values: px, py, pz, errorMsg, _object, _waterPlane, field, x, y, z, w, x2, y2, z2, w2
function PlaceableRiceField.consoleCommandsetWaterShaderParameters(_, r, g, b, a, depthScale, refractionColorScale, getWaterDepthScale, inscatteringScale)
	local v496_, v497_, v498_ = g_localPlayer:getPosition()
	local v499_, _, _, v500_ = PlaceableRiceField.getRiceFieldAtPosition(v496_, v497_, v498_)
	if v499_ == nil then
		local v501_ = tonumber(r)
		local v502_ = tonumber(g)
		local v503_ = tonumber(b)
		local v504_ = tonumber(a)
		local v505_ = tonumber(depthScale)
		local v506_ = tonumber(refractionColorScale)
		local v507_ = tonumber(getWaterDepthScale)
		local v508_ = tonumber(inscatteringScale)
		setShaderParameter(v500_.mesh, "underwaterFogColor", v501_, v502_, v503_, v504_, false)
		setShaderParameter(v500_.mesh, "underwaterFogDepth", v505_, v506_, v507_, v508_, false)
		setShaderParameter(v500_.mirrorMesh, "underwaterFogColor", v501_, v502_, v503_, v504_, false)
		setShaderParameter(v500_.mirrorMesh, "underwaterFogDepth", v505_, v506_, v507_, v508_, false)
		local v509_, v510_, v511_, v512_ = getShaderParameter(v500_.mesh, "underwaterFogColor")
		local v513_, v514_, v515_, v516_ = getShaderParameter(v500_.mesh, "underwaterFogDepth")
		return string.format("underwaterFogColor %.3f %.3f %.3f %.3f\nunderwaterFogDepth %.3f %.3f %.3f %.3f", v509_, v510_, v511_, v512_, v513_, v514_, v515_, v516_)
	end
	printError(v499_)
end

-- Local values: x, y, z, errorMsg, object, _waterPlane, field, spec, fruitType, groundType, densityMapPolygonFoliage, fieldUpdateTaskInner, maxAngle
function PlaceableRiceField.consoleCommandSetRiceState(_, fruitTypeName, stateIndex, groundAngle)
	local v520_ = tonumber(stateIndex)
	local v521_, v522_, v523_ = g_localPlayer:getPosition()
	local v524_, v525_, _, v526_ = PlaceableRiceField.getRiceFieldAtPosition(v521_, v522_, v523_)
	if v524_ == nil then
		local v527_ = v525_.spec_riceField
		local v528_, v529_, v530_
		if fruitTypeName and string.upper(fruitTypeName) == "NONE" then
			v528_ = FruitType.UNKNOWN
			v529_ = FieldGroundType.CULTIVATED
			v530_ = 0
		else
			v528_ = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
			if v528_ == nil or table.find(v527_.fruitTypes, v528_) == nil then
				Logging.error("Unknown or unsupported fruitTypeName %q", fruitTypeName)
				return
			end
			local v531_ = v520_ or v528_.minHarvestingGrowthState
			local v532_ = v528_.numFoliageStates
			v530_ = math.clamp(v531_, 1, v532_)
			v529_ = v528_:getGrowthStateGroundType(v530_)
		end
		local v533_ = DensityMapPolygon.new()
		v533_:updateFromPolygon2D(v526_.polygonFoliage)
		local v534_ = FieldUpdateTask.new()
		v534_:setArea(v533_)
		if v528_ == FruitType.UNKNOWN then
			v534_:setFruit(FruitType.UNKNOWN, v530_)
		else
			v534_:setFruit(v528_.index, v530_)
		end
		if v529_ ~= nil then
			v534_:setGroundType(v529_)
		end
		if groundAngle ~= nil then
			local v535_ = tonumber(groundAngle) or 0
			local v536_ = math.rad(v535_)
			local v537_ = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
			local v538_ = v536_ / 1.5707963267948966
			v534_:setGroundAngle(math.clamp(v538_, 0, 1) * v537_)
		end
		v534_:enqueue()
		return v528_ == FruitType.UNKNOWN and "Removed crops from rice field" or string.format("Updated rice field to %q at growth state %q (index %d)", v528_.name, v528_:getGrowthStateName(v530_), v530_)
	end
	printError(v524_)
end

-- Local values: field, x, _, z, farmland, riceFieldCallback, callbackTarget, riceFieldXMLFilename, existingPlaceableInstance, data, storeItem
function PlaceableRiceField.consoleCommandCreateRiceFieldFromField(_, fieldIndex)
	if g_server == nil then
		printError("Only allowed for server")
	else
		local v_u_540_ = nil
		if fieldIndex == nil then
			local v541_, _, v542_ = g_localPlayer:getPosition()
			local v543_ = g_farmlandManager:getFarmlandAtWorldPosition(v541_, v542_)
			if v543_ ~= nil then
				v_u_540_ = v543_:getField()
			end
		else
			local v544_ = tonumber(fieldIndex)
			if v544_ == nil then
				return "Invalid field index"
			end
			v_u_540_ = g_fieldManager:getFieldById(v544_)
		end
		if v_u_540_ == nil then
			return "Unable to get field"
		end
		print(string.format("Trying to create rice field on field %s", v_u_540_:getName()))
		local function v_u_546_(p545_)
			if p545_ == PlaceableRiceField.BUILD_STATUS.OK then
				print("successfully created rice field")
			else
				Logging.error("Failed to create rice field, reason: %s", EnumUtil.getName(PlaceableRiceField.BUILD_STATUS, p545_))
			end
		end
		local v559_ = {
			["onPlaceableCreated"] = function(_, p547_, _, p548_)
				-- upvalues: (ref) v_u_540_, (copy) v_u_546_
				if p547_ == BuyPlaceableEvent.STATE_SUCCESS then
					local v549_ = NetworkUtil.getObject(p548_)
					local _, v550_, _ = getWorldTranslation(v_u_540_.polygonPoints[1])
					local v551_ = v549_:createNewField(v550_)
					local v552_ = PlaceableRiceField.MIN_VERTEX_DISTANCE
					local v553_ = PlaceableRiceField.MAX_VERTEX_DISTANCE
					PlaceableRiceField.MIN_VERTEX_DISTANCE = 1
					PlaceableRiceField.MAX_VERTEX_DISTANCE = 1000
					for _, v554_ in ipairs(v_u_540_.polygonPoints) do
						local v555_, _, v556_ = getWorldTranslation(v554_)
						local v557_, v558_ = v549_:addVertex(v551_, v555_, v556_)
						if not v557_ then
							Logging.error("Unable to add vertex at %d %d: %s", v555_, v556_, v558_)
							PlaceableRiceField.MIN_VERTEX_DISTANCE = v552_
							PlaceableRiceField.MAX_VERTEX_DISTANCE = v553_
							return
						end
					end
					PlaceableRiceField.MIN_VERTEX_DISTANCE = v552_
					PlaceableRiceField.MAX_VERTEX_DISTANCE = v553_
					v549_:finalizeNewField(v551_, true, v_u_546_)
				else
					Logging.error("Failed to create rice field, unable to load rice field placeable")
				end
			end
		}
		local v560_ = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename("data/placeables/brandless/riceField/riceField.xml", g_currentMission:getFarmId(), true)
		if v560_ == nil then
			local v561_ = BuyPlaceableData.new()
			v561_:setStoreItem((g_storeManager:getItemByXMLFilename("data/placeables/brandless/riceField/riceField.xml")))
			v561_:setPosition(0, 0, 0)
			v561_:setRotation(0, 0, 0)
			v561_:setIsFreeOfCharge(false)
			v561_:setConfigurations({})
			v561_:setOwnerFarmId(g_localPlayer.farmId)
			v561_:setDisplacementCosts(0)
			v561_:setModifyTerrain(false)
			v561_:updatePrice()
			g_messageCenter:subscribeOneshot(BuyPlaceableEvent, v559_.onPlaceableCreated, v559_)
			g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(v561_))
		else
			v559_.onPlaceableCreated(nil, BuyPlaceableEvent.STATE_SUCCESS, nil, v560_.id)
		end
	end
end
