Twister = {}
local Twister_mt = Class(Twister, Object)
g_xmlManager:addCreateSchemaFunction(function()
	Twister.xmlSchema = XMLSchema.new("twister")
end)
g_xmlManager:addInitSchemaFunction(function()
	local schema = Twister.xmlSchema
	I3DUtil.registerI3dMappingXMLPaths(schema, "twister")
	schema:register(XMLValueType.STRING, "twister.annotation", "Copyright annotation")
	schema:register(XMLValueType.STRING, "twister.filename", "Filepath to i3d file")
	schema:register(XMLValueType.FLOAT, "twister.fading#fadeInDuration", "Fade in duration in seconds", 1, false)
	schema:register(XMLValueType.FLOAT, "twister.fading#fadeOutDuration", "Fade out duration in seconds", 1, false)
	schema:register(XMLValueType.FLOAT, "twister.speed#meterPerSecond", "Speed in meter per second", 1, false)
	DensityMapNodePolygon.registerXMLPaths(schema, "twister.destructionAreas.destructionArea(?)")
	schema:register(XMLValueType.INT, "twister.destructionAreas.destructionArea(?)#perlinPercentage", "Perlin noise persistence of the area")
	schema:register(XMLValueType.INT, "twister.objectDestruction#radius", "Radius in which objects are affected by the twister")
	schema:register(XMLValueType.INT, "twister.objectDestruction#innerRadius", "Radius in which objects are always destroyed by the twister")
	schema:register(XMLValueType.INT, "twister.objectDestruction#height", "Height in which objects are always destroyed by the twister")
	SoundManager.registerSampleXMLPaths(schema, "twister.sounds", "moving")
end)
function Twister.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or Twister_mt)
	self.xmlFile = nil
	self.baseDirectory = nil
	self.node = nil
	self.isSpawned = false
	self.foundObjects = {}
	self.currentObjects = {}
	self.i3dMappings = nil
	self.components = nil
	self.destructionAreas = nil
	self.destructionAreaIndex = 0
	self.destructionAffectedFarmIds = {}
	self.metersPerHour = 0
	self.fadeValue = 0
	self.fadeDirection = 0
	self.fadeInDurationMs = 6000
	self.fadeOutDurationMs = 2000
	self.objectDestructionRadius = 30
	self.objectDestructionInnerRadius = 10
	self.objectDestructionHeight = 30
	self.samples = nil
	self.dirtyFlag = self:getNextDirtyFlag()
	self.rootNode = createTransformGroup("twisterRootNode")
	link(getRootNode(), self.rootNode)
	setVisibility(self.rootNode, false)
	self.mapHotspot = TwisterHotspot.new()
	local x, y, z = getTranslation(self.rootNode)
	if not isServer then
		self.networkTimeInterpolator = InterpolationTime.new(1.2)
		self.positionInterpolator = InterpolatorPosition.new(x, y, z)
		self.fadeInterpolator = InterpolatorValue.new(self.fadeValue)
		self.fadeInterpolator:setMinMax(0, 1)
		return self
	else
		self.sendPosX = x
		self.sendPosY = y
		self.sendPosZ = z
		self.sendFadeValue = self.fadeValue
		return self
	end
end
function Twister:load(environmentXMLFile, key, baseDirectory)
	local filename = environmentXMLFile:getString(key .. "#filename")
	if filename == nil then
		return false
	end
	filename = Utils.getFilename(filename, baseDirectory)
	self.xmlFile = XMLFile.load("twister", filename, Twister.xmlSchema)
	self.baseDirectory = baseDirectory
	self.configFileName = filename
	self.treeTypeIndex = g_treePlantManager:getTreeTypeIndexFromName("ravaged")
	if self.xmlFile == nil then
		return false
	else
		local i3dFilename = Utils.getFilename(self.xmlFile:getValue("twister.filename"), baseDirectory)
		self.loadRequestId = g_i3DManager:loadI3DFileAsync(i3dFilename, true, false, self.onI3DFileLoaded, self)
		return true
	end
end
function Twister:onI3DFileLoaded(i3dNode, failedReason, args)
	self.loadRequestId = nil
	if failedReason == LoadI3DFailedReason.NONE then
		self.components = I3DUtil.loadI3DComponents(i3dNode)
		self.i3dMappings = I3DUtil.loadI3DMapping(self.xmlFile, "twister", self.components)
		for _, component in ipairs(self.components) do
			link(self.rootNode, component.node)
		end
		if self.isServer then
			for _, key in self.xmlFile:iterator("twister.destructionAreas.destructionArea") do
				local polygon = DensityMapNodePolygon.createFromXMLFile(self.xmlFile, key, self.components, self.i3dMappings)
				local perlinPercentage = self.xmlFile:getValue(key .. "#perlinPercentage", 2500)
				if polygon == nil then
					continue
				end
				if self.destructionAreas == nil then
					self.destructionAreas = {}
					self.destructionAreaIndex = 1
				end
				table.insert(self.destructionAreas, { polygon = polygon, perlinPercentage = perlinPercentage })
			end
		end
		self.fadeInDurationMs = self.xmlFile:getValue("twister.fading#fadeInDuration", 1) * 1000
		self.fadeOutDurationMs = self.xmlFile:getValue("twister.fading#fadeOutDuration", 1) * 1000
		self.meterPerSecond = self.xmlFile:getValue("twister.speed#meterPerSecond", 1) / 1000
		self.objectDestructionRadius = self.xmlFile:getValue("twister.objectDestruction#radius", 10)
		self.objectDestructionInnerRadius = self.xmlFile:getValue("twister.objectDestruction#innerRadius", 30)
		self.objectDestructionHeight = self.xmlFile:getValue("twister.objectDestruction#height", 30)
		if self.isClient then
			self.samples = {}
			self.samples.moving = g_soundManager:loadSampleFromXML(self.xmlFile, "twister.sounds", "moving", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT)
		end
		self:setFadeValue(self.fadeValue, true)
		delete(i3dNode)
	end
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
end
function Twister:saveToXMLFile(xmlFile, key)
	local x, y, z = getWorldTranslation(self.rootNode)
	xmlFile:setString(key .. "#position", string.format("%.2f %.2f %.2f", x, y, z))
	xmlFile:setBool(key .. "#isSpawned", self.isSpawned)
	xmlFile:setInt(key .. "#fadeDirection", self.fadeDirection)
	xmlFile:setFloat(key .. "#fadeValue", self.fadeValue)
	xmlFile:setFloat(key .. "#metersPerHour", self.metersPerHour)
	local i = 0
	for farmId, _ in pairs(self.destructionAffectedFarmIds) do
		xmlFile:setInt(string.format("%s.affectedFarm(%d)#farmId", key, i), farmId)
		i = i + 1
	end
end
function Twister:loadFromXMLFile(xmlFile, key)
	local position = xmlFile:getVector(key .. "#position", nil, 3)
	if position ~= nil then
		setWorldTranslation(self.rootNode, unpack(position))
	end
	self.isSpawned = xmlFile:getBool(key .. "#isSpawned", self.isSpawned)
	self.fadeDirection = xmlFile:getInt(key .. "#fadeDirection", self.fadeDirection)
	self.fadeValue = xmlFile:getFloat(key .. "#fadeValue", self.fadeValue)
	self.metersPerHour = xmlFile:getFloat(key .. "#metersPerHour", self.metersPerHour)
	for _, farmKey in xmlFile:iterator(key .. ".affectedFarm") do
		local farmId = xmlFile:getInt(farmKey .. "#farmId")
		if farmId == nil then
			continue
		end
		self.destructionAffectedFarmIds[farmId] = true
	end
end
function Twister:delete()
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end
	if self.rootNode ~= nil then
		delete(self.rootNode)
		self.rootNode = nil
	end
	if self.mapHotspot ~= nil then
		self.mapHotspot:delete()
	end
	Twister:superClass().delete(self)
end
function Twister:readStream(streamId, connection)
	Twister:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local mission = g_currentMission
		local paramsXZ = mission.vehicleXZPosCompressionParams
		local paramsY = mission.vehicleYPosCompressionParams
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		setWorldTranslation(self.rootNode, x, y, z)
		local fadeValue = streamReadFloat32(streamId)
		self:setFadeValue(fadeValue, true)
		self.networkTimeInterpolator:reset()
	end
end
function Twister:writeStream(streamId, connection)
	Twister:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		local mission = g_currentMission
		local x, y, z = getWorldTranslation(self.rootNode)
		local paramsXZ = mission.vehicleXZPosCompressionParams
		local paramsY = mission.vehicleYPosCompressionParams
		NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
		streamWriteFloat32(streamId, self.fadeValue)
	end
end
function Twister:readUpdateStream(streamId, timestamp, connection)
	Twister:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local mission = g_currentMission
		local paramsXZ = mission.vehicleXZPosCompressionParams
		local paramsY = mission.vehicleYPosCompressionParams
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local fadeValue = streamReadFloat32(streamId)
		self.positionInterpolator:setTargetPosition(x, y, z)
		self.fadeInterpolator:setTargetValue(fadeValue)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end
function Twister:writeUpdateStream(streamId, connection, dirtyMask)
	Twister:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() and streamWriteBool(streamId, bit32.band(dirtyMask, self.dirtyFlag) ~= 0) then
		local mission = g_currentMission
		local paramsXZ = mission.vehicleXZPosCompressionParams
		local paramsY = mission.vehicleYPosCompressionParams
		NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosX, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosY, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosZ, paramsXZ)
		streamWriteFloat32(streamId, self.sendFadeValue)
	end
end
function Twister:update(dt)
	if self.isServer then
		local needsUpdate = self.fadeDirection ~= 0 or 0 < self.fadeValue
		if self.fadeDirection ~= 0 then
			local duration = self.fadeInDurationMs
			if self.fadeDirection < 0 then
				duration = self.fadeOutDurationMs
			end
			local fadeValue = math.clamp(self.fadeValue + self.fadeDirection * (dt / duration), 0, 1)
			self:setFadeValue(fadeValue)
			if self.fadeDirection == 1 and (self.fadeValue == 1 or self.fadeDirection == -1 and self.fadeValue == 0) then
				self.fadeDirection = 0
			end
		end
		if needsUpdate then
			self:move(dt)
			local mission = g_currentMission
			if mission.missionInfo.disasterDestructionState == DisasterDestructionState.ENABLED then
				self:updateObjectDestruction()
				self:updateDestructionAreas()
			end
			self:raiseActive()
		end
	else
		self.networkTimeInterpolator:update(dt)
		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
		local x, y, z = self.positionInterpolator:getInterpolatedValues(interpolationAlpha)
		setWorldTranslation(self.rootNode, x, y, z)
		local fadeValue = self.fadeInterpolator:getInterpolatedValue(interpolationAlpha)
		self:setFadeValue(fadeValue)
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	if self.isHotspotAdded then
		local x, _, z = getWorldTranslation(self.rootNode)
		self.mapHotspot:setWorldPosition(x, z)
	end
end
function Twister:spawn(x, z, metersPerHour)
	if not self.isServer then
		self.networkTimeInterpolator:reset()
	end
	if x ~= nil and z ~= nil then
		local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		setWorldTranslation(self.rootNode, x, y, z)
	end
	self.fadeDirection = 1
	self.isSpawned = true
	if metersPerHour ~= nil then
		self.metersPerHour = metersPerHour
	end
	self:addHotspots()
	self.mapHotspot:setWorldPosition(x, z)
	self:raiseActive()
end
function Twister:despawn()
	if self.isSpawned then
		self.isSpawned = false
		self.fadeDirection = -1
		self.foundObjects = {}
		self.currentObjects = {}
	end
	if self.isServer then
		local mission = g_currentMission
		for farmId, _ in pairs(self.destructionAffectedFarmIds) do
			local event = TwisterDestructionNotificationEvent.new()
			mission:broadcastEventToFarm(event, farmId, true)
		end
		self.destructionAffectedFarmIds = {}
	end
	self:removeHotspot()
	self:raiseActive()
end
function Twister:onStart()
	if self.samples ~= nil then
		g_soundManager:playSample(self.samples.moving)
	end
end
function Twister:onEnd()
	if self.samples ~= nil then
		g_soundManager:stopSample(self.samples.moving)
	end
end
function Twister:move(dt)
	if not self.isServer then
		return
	else
		local mission = g_currentMission
		local weather = mission.environment.weather
		local windUpdater = weather.windUpdater
		local windDirX, windDirZ, _, _ = windUpdater:getCurrentValues()
		local meterPerMs = self.metersPerHour / 3600000 * mission:getEffectiveTimeScale()
		local dirX, dirZ = MathUtil.vector2Normalize(windDirX, windDirZ)
		local x, y, z = getWorldTranslation(self.rootNode)
		x = x + dirX * dt * meterPerMs
		z = z + dirZ * dt * meterPerMs
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		setWorldTranslation(self.rootNode, x, y, z)
		setWorldDirection(self.rootNode, windDirX, 0, windDirZ, 0, 1, 0)
		local hasMoved = true
		if not (0.005 < math.abs(self.sendPosX - x)) then
			hasMoved = true
			if not (0.005 < math.abs(self.sendPosY - y)) then
				hasMoved = 0.005 < math.abs(self.sendPosZ - z)
			end
		end
		if hasMoved then
			self.sendPosX = x
			self.sendPosY = y
			self.sendPosZ = z
			self:raiseDirtyFlags(self.dirtyFlag)
		end
		if self.isSpawned then
			local stopTwister = false
			local terrainSize = mission.terrainSize * 0.5 - 20
			if terrainSize < x or terrainSize < z then
				stopTwister = true
			end
			if mission.missionInfo.disasterDestructionState == DisasterDestructionState.DISABLED then
				stopTwister = true
			end
			if stopTwister then
				g_server:broadcastEvent(TwisterStopEvent.new(), true)
			end
		end
	end
end
function Twister:setFadeValue(fadeValue, isInitialLoading)
	if not isInitialLoading and self.fadeValue == 0 then
		if 0 < fadeValue then
			self:onStart()
		elseif 0 < self.fadeValue then
			if fadeValue == 0 then
				self:onEnd()
			end
		end
	end
	setVisibility(self.rootNode, 0 < fadeValue)
	I3DUtil.setShaderParameterRec(self.rootNode, "fadeProgress", nil, 1 - fadeValue, nil, nil)
	self.fadeValue = fadeValue
	if self.isServer and (0.01 < math.abs(fadeValue - self.sendFadeValue) or fadeValue == 0 or fadeValue == 1) then
		self:raiseDirtyFlags(self.dirtyFlag)
		self.sendFadeValue = fadeValue
	end
end
function Twister:updateObjectDestruction()
	if self.isSpawned and (self.fadeValue == 1 and not self.objectCheckPending) then
		self.objectCheckPending = true
		local x, y, z = getWorldTranslation(self.rootNode)
		local radius = self.objectDestructionRadius
		local height = self.objectDestructionHeight
		local collisionMask = CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.BUILDING
		self.foundObjects = {}
		overlapCylinderAsync(x, y + height * 0.5, z, radius, height, Axis.Y, "onObjectCallback", self, collisionMask)
	end
end
function Twister:updateDestructionAreas()
	if self.isSpawned and (self.fadeValue == 1 and self.destructionAreas ~= nil) then
		local info = self.destructionAreas[self.destructionAreaIndex]
		FSDensityMapUtil.updateDisasterArea(info.polygon, info.perlinPercentage)
		self.destructionAreaIndex = self.destructionAreaIndex + 1
		if #self.destructionAreas < self.destructionAreaIndex then
			self.destructionAreaIndex = 1
		end
	end
end
function Twister:onFinishCallback()
	local mission = g_currentMission
	if mission == nil then
		return
	else
		local mappedObjects = {}
		for node, _ in pairs(self.currentObjects) do
			if not entityExists(node) or self.foundObjects[node] == nil then
				self.currentObjects[node] = nil
			end
			local object = mission:getNodeObject(node)
			if object == nil then
				continue
			end
			mappedObjects[object] = true
		end
		for node, nodeInfo in pairs(self.foundObjects) do
			local object = mission:getNodeObject(node)
			if entityExists(node) and (self.currentObjects[node] == nil and mappedObjects[object] == nil) then
				local destructionDistance = MathUtil.lerp(self.objectDestructionInnerRadius, self.objectDestructionRadius, math.random())
				local destructObject = math.random() < 0.3
				local isBale = nodeInfo.isBale
				local isPlaceable = nodeInfo.isPlaceable
				if isBale or isPlaceable then
					destructObject = true
				end
				local info = { isBale = isBale, isPlaceable = isPlaceable, destructObject = destructObject, destructionDistance = destructionDistance, isSplitShape = nodeInfo.isSplitShape }
				self.currentObjects[node] = info
			end
		end
		for node, info in pairs(self.currentObjects) do
			local distance = calcDistanceFrom(node, self.rootNode)
			if info.destructObject and (not (distance < info.destructionDistance) and distance < self.objectDestructionInnerRadius) then
				Logging.devInfo("Twister: Destroy object '%s'", getName(node))
				if info.isBale then
					local x, _, z = getWorldTranslation(node)
					local isInside = mission.indoorMask:getIsIndoorAtWorldPosition(x, z)
					if not isInside then
						local bale = mission:getNodeObject(node)
						if bale:getCanBeSold() then
							local farmId = bale:getOwnerFarmId()
							if farmId ~= nil then
								self.destructionAffectedFarmIds[farmId] = true
							end
							bale:delete()
						end
					end
				elseif info.isPlaceable then
					local placeable = mission:getNodeObject(node)
					local success = placeable:destruct()
					if success then
						local farmId = placeable:getOwnerFarmId()
						if farmId ~= nil then
							self.destructionAffectedFarmIds[farmId] = true
						end
					end
				elseif info.isSplitShape then
					local x, _, z = getWorldTranslation(getParent(node))
					local farmId = g_farmlandManager:getOwnerIdAtWorldPosition(x, z)
					if farmId ~= nil then
						self.destructionAffectedFarmIds[farmId] = true
					end
					g_treePlantManager:replaceWithTreeType(getParent(node), self.treeTypeIndex)
				end
				self.currentObjects[node] = nil
			end
		end
		self.objectCheckPending = false
	end
end
function Twister:baleOutsideCallback(node, x, y, z, distance, nx, ny, nz, subshapeIndex, shapeId, isLast)
	self.isBaleOutside = false
end
function Twister:onObjectCallback(transformId, subShapeIndex, isLast)
	local mission = g_currentMission
	if mission == nil then
		return false
	else
		if transformId ~= 0 then
			local object = mission:getNodeObject(transformId)
			if object ~= nil then
				if object:isa(Bale) then
					self.foundObjects[transformId] = { isSplitShape = false, isBale = true, isPlaceable = false }
				elseif object ~= nil then
					if object:isa(Placeable) and object.getCanBeDestructedByTwister ~= nil then
						if object:getCanBeDestructedByTwister() then
							self.foundObjects[transformId] = { isSplitShape = false, isBale = false, isPlaceable = true }
						elseif getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) then
							if not getIsSplitShapeSplit(transformId) then
								local splitTypeIndex = getSplitType(transformId)
								local treeType = g_treePlantManager:getTreeTypeDescFromSplitType(splitTypeIndex)
								if treeType ~= nil and treeType.index ~= self.treeTypeIndex then
									self.foundObjects[transformId] = { isSplitShape = true, isBale = false, isPlaceable = false }
								end
							end
						end
					end
				end
			end
		end
		if isLast then
			self:onFinishCallback()
		end
		return true
	end
end
function Twister:addHotspots()
	if self.mapHotspot ~= nil then
		self.isHotspotAdded = true
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
end
function Twister:removeHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
end
