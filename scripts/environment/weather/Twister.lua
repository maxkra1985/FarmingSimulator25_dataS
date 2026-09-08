-- Local values: Twister_mt
Twister = {}
local Twister_mt = Class(Twister, Object)
g_xmlManager:addCreateSchemaFunction(function()
	Twister.xmlSchema = XMLSchema.new("twister")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = Twister.xmlSchema
	I3DUtil.registerI3dMappingXMLPaths(v2_, "twister")
	v2_:register(XMLValueType.STRING, "twister.annotation", "Copyright annotation")
	v2_:register(XMLValueType.STRING, "twister.filename", "Filepath to i3d file")
	v2_:register(XMLValueType.FLOAT, "twister.fading#fadeInDuration", "Fade in duration in seconds", 1, false)
	v2_:register(XMLValueType.FLOAT, "twister.fading#fadeOutDuration", "Fade out duration in seconds", 1, false)
	v2_:register(XMLValueType.FLOAT, "twister.speed#meterPerSecond", "Speed in meter per second", 1, false)
	DensityMapNodePolygon.registerXMLPaths(v2_, "twister.destructionAreas.destructionArea(?)")
	v2_:register(XMLValueType.INT, "twister.destructionAreas.destructionArea(?)#perlinPercentage", "Perlin noise persistence of the area")
	v2_:register(XMLValueType.INT, "twister.objectDestruction#radius", "Radius in which objects are affected by the twister")
	v2_:register(XMLValueType.INT, "twister.objectDestruction#innerRadius", "Radius in which objects are always destroyed by the twister")
	v2_:register(XMLValueType.INT, "twister.objectDestruction#height", "Height in which objects are always destroyed by the twister")
	SoundManager.registerSampleXMLPaths(v2_, "twister.sounds", "moving")
end)

-- Upvalues: Twister_mt
-- Local values: self, x, y, z
function Twister.new(isServer, isClient, customMt)
	-- upvalues: (copy) Twister_mt
	local v6_ = Object.new(isServer, isClient, customMt or Twister_mt)
	v6_.xmlFile = nil
	v6_.baseDirectory = nil
	v6_.node = nil
	v6_.isSpawned = false
	v6_.foundObjects = {}
	v6_.currentObjects = {}
	v6_.i3dMappings = nil
	v6_.components = nil
	v6_.destructionAreas = nil
	v6_.destructionAreaIndex = 0
	v6_.destructionAffectedFarmIds = {}
	v6_.metersPerHour = 0
	v6_.fadeValue = 0
	v6_.fadeDirection = 0
	v6_.fadeInDurationMs = 6000
	v6_.fadeOutDurationMs = 2000
	v6_.objectDestructionRadius = 30
	v6_.objectDestructionInnerRadius = 10
	v6_.objectDestructionHeight = 30
	v6_.samples = nil
	v6_.dirtyFlag = v6_:getNextDirtyFlag()
	v6_.rootNode = createTransformGroup("twisterRootNode")
	link(getRootNode(), v6_.rootNode)
	setVisibility(v6_.rootNode, false)
	v6_.mapHotspot = TwisterHotspot.new()
	local v7_, v8_, v9_ = getTranslation(v6_.rootNode)
	if isServer then
		v6_.sendPosX = v7_
		v6_.sendPosY = v8_
		v6_.sendPosZ = v9_
		v6_.sendFadeValue = v6_.fadeValue
		return v6_
	else
		v6_.networkTimeInterpolator = InterpolationTime.new(1.2)
		v6_.positionInterpolator = InterpolatorPosition.new(v7_, v8_, v9_)
		v6_.fadeInterpolator = InterpolatorValue.new(v6_.fadeValue)
		v6_.fadeInterpolator:setMinMax(0, 1)
		return v6_
	end
end

-- Local values: filename, i3dFilename
function Twister:load(environmentXMLFile, key, baseDirectory)
	local v14_ = environmentXMLFile:getString(key .. "#filename")
	if v14_ == nil then
		return false
	end
	local v15_ = Utils.getFilename(v14_, baseDirectory)
	self.xmlFile = XMLFile.load("twister", v15_, Twister.xmlSchema)
	self.baseDirectory = baseDirectory
	self.configFileName = v15_
	self.treeTypeIndex = g_treePlantManager:getTreeTypeIndexFromName("ravaged")
	if self.xmlFile == nil then
		return false
	end
	local v16_ = Utils.getFilename(self.xmlFile:getValue("twister.filename"), baseDirectory)
	self.loadRequestId = g_i3DManager:loadI3DFileAsync(v16_, true, false, self.onI3DFileLoaded, self)
	return true
end

-- Local values: _, component, _, key, polygon, perlinPercentage
function Twister:onI3DFileLoaded(i3dNode, failedReason, args)
	self.loadRequestId = nil
	if failedReason == LoadI3DFailedReason.NONE then
		self.components = I3DUtil.loadI3DComponents(i3dNode)
		self.i3dMappings = I3DUtil.loadI3DMapping(self.xmlFile, "twister", self.components)
		for _, v20_ in ipairs(self.components) do
			link(self.rootNode, v20_.node)
		end
		if self.isServer then
			for _, v21_ in self.xmlFile:iterator("twister.destructionAreas.destructionArea") do
				local v22_ = DensityMapNodePolygon.createFromXMLFile(self.xmlFile, v21_, self.components, self.i3dMappings)
				local v23_ = self.xmlFile:getValue(v21_ .. "#perlinPercentage", 2500)
				if v22_ ~= nil then
					if self.destructionAreas == nil then
						self.destructionAreas = {}
						self.destructionAreaIndex = 1
					end
					local v24_ = self.destructionAreas
					table.insert(v24_, {
						["polygon"] = v22_,
						["perlinPercentage"] = v23_
					})
				end
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

-- Local values: x, y, z, i, farmId, _
function Twister:saveToXMLFile(xmlFile, key)
	local v28_, v29_, v30_ = getWorldTranslation(self.rootNode)
	xmlFile:setString(key .. "#position", string.format("%.2f %.2f %.2f", v28_, v29_, v30_))
	xmlFile:setBool(key .. "#isSpawned", self.isSpawned)
	xmlFile:setInt(key .. "#fadeDirection", self.fadeDirection)
	xmlFile:setFloat(key .. "#fadeValue", self.fadeValue)
	xmlFile:setFloat(key .. "#metersPerHour", self.metersPerHour)
	local v31_ = 0
	for v32_, _ in pairs(self.destructionAffectedFarmIds) do
		xmlFile:setInt(string.format("%s.affectedFarm(%d)#farmId", key, v31_), v32_)
		v31_ = v31_ + 1
	end
end

-- Local values: position, _, farmKey, farmId
function Twister:loadFromXMLFile(xmlFile, key)
	local v36_ = xmlFile:getVector(key .. "#position", nil, 3)
	if v36_ ~= nil then
		setWorldTranslation(self.rootNode, unpack(v36_))
	end
	self.isSpawned = xmlFile:getBool(key .. "#isSpawned", self.isSpawned)
	self.fadeDirection = xmlFile:getInt(key .. "#fadeDirection", self.fadeDirection)
	self.fadeValue = xmlFile:getFloat(key .. "#fadeValue", self.fadeValue)
	self.metersPerHour = xmlFile:getFloat(key .. "#metersPerHour", self.metersPerHour)
	for _, v37_ in xmlFile:iterator(key .. ".affectedFarm") do
		local v38_ = xmlFile:getInt(v37_ .. "#farmId")
		if v38_ ~= nil then
			self.destructionAffectedFarmIds[v38_] = true
		end
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

-- Local values: mission, paramsXZ, paramsY, x, y, z, fadeValue
function Twister:readStream(streamId, connection)
	Twister:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local v43_ = g_currentMission
		local v44_ = v43_.vehicleXZPosCompressionParams
		local v45_ = v43_.vehicleYPosCompressionParams
		local v46_ = NetworkUtil.readCompressedWorldPosition(streamId, v44_)
		local v47_ = NetworkUtil.readCompressedWorldPosition(streamId, v45_)
		local v48_ = NetworkUtil.readCompressedWorldPosition(streamId, v44_)
		setWorldTranslation(self.rootNode, v46_, v47_, v48_)
		self:setFadeValue(streamReadFloat32(streamId), true)
		self.networkTimeInterpolator:reset()
	end
end

-- Local values: mission, x, y, z, paramsXZ, paramsY
function Twister:writeStream(streamId, connection)
	Twister:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		local v52_ = g_currentMission
		local v53_, v54_, v55_ = getWorldTranslation(self.rootNode)
		local v56_ = v52_.vehicleXZPosCompressionParams
		local v57_ = v52_.vehicleYPosCompressionParams
		NetworkUtil.writeCompressedWorldPosition(streamId, v53_, v56_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v54_, v57_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v55_, v56_)
		streamWriteFloat32(streamId, self.fadeValue)
	end
end

-- Local values: mission, paramsXZ, paramsY, x, y, z, fadeValue
function Twister:readUpdateStream(streamId, timestamp, connection)
	Twister:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v62_ = g_currentMission
		local v63_ = v62_.vehicleXZPosCompressionParams
		local v64_ = v62_.vehicleYPosCompressionParams
		local v65_ = NetworkUtil.readCompressedWorldPosition(streamId, v63_)
		local v66_ = NetworkUtil.readCompressedWorldPosition(streamId, v64_)
		local v67_ = NetworkUtil.readCompressedWorldPosition(streamId, v63_)
		local v68_ = streamReadFloat32(streamId)
		self.positionInterpolator:setTargetPosition(v65_, v66_, v67_)
		self.fadeInterpolator:setTargetValue(v68_)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end

-- Local values: mission, paramsXZ, paramsY
function Twister:writeUpdateStream(streamId, connection, dirtyMask)
	Twister:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v73_ = streamWriteBool
		local v74_ = self.dirtyFlag
		if v73_(streamId, bit32.band(dirtyMask, v74_) ~= 0) then
			local v75_ = g_currentMission
			local v76_ = v75_.vehicleXZPosCompressionParams
			local v77_ = v75_.vehicleYPosCompressionParams
			NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosX, v76_)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosY, v77_)
			NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosZ, v76_)
			streamWriteFloat32(streamId, self.sendFadeValue)
		end
	end
end

-- Local values: needsUpdate, duration, fadeValue, mission, interpolationAlpha, x, y, z, fadeValue, x, _, z
function Twister:update(dt)
	if self.isServer then
		local v80_ = self.fadeDirection ~= 0 and true or self.fadeValue > 0
		if self.fadeDirection ~= 0 then
			local v81_ = self.fadeInDurationMs
			if self.fadeDirection < 0 then
				v81_ = self.fadeOutDurationMs
			end
			local v82_ = self.fadeValue + self.fadeDirection * (dt / v81_)
			self:setFadeValue((math.clamp(v82_, 0, 1)))
			if self.fadeDirection == 1 and self.fadeValue == 1 or self.fadeDirection == -1 and self.fadeValue == 0 then
				self.fadeDirection = 0
			end
		end
		if v80_ then
			self:move(dt)
			if g_currentMission.missionInfo.disasterDestructionState == DisasterDestructionState.ENABLED then
				self:updateObjectDestruction()
				self:updateDestructionAreas()
			end
			self:raiseActive()
		end
	else
		self.networkTimeInterpolator:update(dt)
		local v83_ = self.networkTimeInterpolator:getAlpha()
		local v84_, v85_, v86_ = self.positionInterpolator:getInterpolatedValues(v83_)
		setWorldTranslation(self.rootNode, v84_, v85_, v86_)
		self:setFadeValue((self.fadeInterpolator:getInterpolatedValue(v83_)))
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	if self.isHotspotAdded then
		local v87_, _, v88_ = getWorldTranslation(self.rootNode)
		self.mapHotspot:setWorldPosition(v87_, v88_)
	end
end

-- Local values: y
function Twister:spawn(x, z, metersPerHour)
	if not self.isServer then
		self.networkTimeInterpolator:reset()
	end
	if x ~= nil and z ~= nil then
		local v93_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		setWorldTranslation(self.rootNode, x, v93_, z)
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

-- Local values: mission, farmId, _, event
function Twister:despawn()
	if self.isSpawned then
		self.isSpawned = false
		self.fadeDirection = -1
		self.foundObjects = {}
		self.currentObjects = {}
	end
	if self.isServer then
		local v95_ = g_currentMission
		for v96_, _ in pairs(self.destructionAffectedFarmIds) do
			v95_:broadcastEventToFarm(TwisterDestructionNotificationEvent.new(), v96_, true)
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

-- Local values: mission, weather, windUpdater, windDirX, windDirZ, _, _, meterPerMs, dirX, dirZ, x, y, z, hasMoved, stopTwister, terrainSize
function Twister:move(dt)
	if self.isServer then
		local v101_ = g_currentMission
		local v102_, v103_, _, _ = v101_.environment.weather.windUpdater:getCurrentValues()
		local v104_ = self.metersPerHour / 3600000 * v101_:getEffectiveTimeScale()
		local v105_, v106_ = MathUtil.vector2Normalize(v102_, v103_)
		local v107_, _, v108_ = getWorldTranslation(self.rootNode)
		local v109_ = v107_ + v105_ * dt * v104_
		local v110_ = v108_ + v106_ * dt * v104_
		local v111_ = getTerrainHeightAtWorldPos(g_terrainNode, v109_, 0, v110_)
		setWorldTranslation(self.rootNode, v109_, v111_, v110_)
		setWorldDirection(self.rootNode, v102_, 0, v103_, 0, 1, 0)
		local v112_ = self.sendPosX - v109_
		local v113_
		if math.abs(v112_) > 0.005 then
			v113_ = true
		else
			local v114_ = self.sendPosY - v111_
			if math.abs(v114_) > 0.005 then
				v113_ = true
			else
				local v115_ = self.sendPosZ - v110_
				v113_ = math.abs(v115_) > 0.005
			end
		end
		if v113_ then
			self.sendPosX = v109_
			self.sendPosY = v111_
			self.sendPosZ = v110_
			self:raiseDirtyFlags(self.dirtyFlag)
		end
		if self.isSpawned then
			local v116_ = v101_.terrainSize * 0.5 - 20
			local v117_ = v116_ < v109_ or v116_ < v110_
			if v101_.missionInfo.disasterDestructionState == DisasterDestructionState.DISABLED and true or v117_ then
				g_server:broadcastEvent(TwisterStopEvent.new(), true)
			end
		end
	end
end

function Twister:setFadeValue(fadeValue, isInitialLoading)
	if (isInitialLoading or self.fadeValue == 0) and fadeValue > 0 then
		self:onStart()
	elseif self.fadeValue > 0 and fadeValue == 0 then
		self:onEnd()
	end
	setVisibility(self.rootNode, fadeValue > 0)
	I3DUtil.setShaderParameterRec(self.rootNode, "fadeProgress", nil, 1 - fadeValue, nil, nil)
	self.fadeValue = fadeValue
	if self.isServer then
		local v121_ = fadeValue - self.sendFadeValue
		if math.abs(v121_) > 0.01 or (fadeValue == 0 or fadeValue == 1) then
			self:raiseDirtyFlags(self.dirtyFlag)
			self.sendFadeValue = fadeValue
		end
	end
end

-- Local values: x, y, z, radius, height, collisionMask
function Twister:updateObjectDestruction()
	if self.isSpawned and (self.fadeValue == 1 and not self.objectCheckPending) then
		self.objectCheckPending = true
		local v123_, v124_, v125_ = getWorldTranslation(self.rootNode)
		local v126_ = self.objectDestructionRadius
		local v127_ = self.objectDestructionHeight
		local v128_ = CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.BUILDING
		self.foundObjects = {}
		overlapCylinderAsync(v123_, v124_ + v127_ * 0.5, v125_, v126_, v127_, Axis.Y, "onObjectCallback", self, v128_)
	end
end

-- Local values: info
function Twister:updateDestructionAreas()
	if self.isSpawned and (self.fadeValue == 1 and self.destructionAreas ~= nil) then
		local v130_ = self.destructionAreas[self.destructionAreaIndex]
		FSDensityMapUtil.updateDisasterArea(v130_.polygon, v130_.perlinPercentage)
		self.destructionAreaIndex = self.destructionAreaIndex + 1
		if self.destructionAreaIndex > #self.destructionAreas then
			self.destructionAreaIndex = 1
		end
	end
end

-- Local values: mission, mappedObjects, node, _, object, node, nodeInfo, object, destructionDistance, destructObject, isBale, isPlaceable, info, node, info, distance, x, _, z, isInside, bale, farmId, placeable, success, farmId, x, _, z, farmId
function Twister:onFinishCallback()
	local v132_ = g_currentMission
	if v132_ ~= nil then
		local v133_ = {}
		for v134_, _ in pairs(self.currentObjects) do
			if not entityExists(v134_) or self.foundObjects[v134_] == nil then
				self.currentObjects[v134_] = nil
			end
			local v135_ = v132_:getNodeObject(v134_)
			if v135_ ~= nil then
				v133_[v135_] = true
			end
		end
		for v136_, v137_ in pairs(self.foundObjects) do
			local v138_ = v132_:getNodeObject(v136_)
			if entityExists(v136_) and (self.currentObjects[v136_] == nil and v133_[v138_] == nil) then
				local v139_ = MathUtil.lerp(self.objectDestructionInnerRadius, self.objectDestructionRadius, math.random())
				local v140_ = math.random() < 0.3
				local v141_ = v137_.isBale
				local v142_ = v137_.isPlaceable
				local v143_ = {
					["isSplitShape"] = v137_.isSplitShape,
					["isBale"] = v141_,
					["isPlaceable"] = v142_,
					["destructObject"] = (v141_ or v142_) and true or v140_,
					["destructionDistance"] = v139_
				}
				self.currentObjects[v136_] = v143_
			end
		end
		for v144_, v145_ in pairs(self.currentObjects) do
			local v146_ = calcDistanceFrom(v144_, self.rootNode)
			if v145_.destructObject and v146_ < v145_.destructionDistance or v146_ < self.objectDestructionInnerRadius then
				Logging.devInfo("Twister: Destroy object \'%s\'", getName(v144_))
				if v145_.isBale then
					local v147_, _, v148_ = getWorldTranslation(v144_)
					if not v132_.indoorMask:getIsIndoorAtWorldPosition(v147_, v148_) then
						local v149_ = v132_:getNodeObject(v144_)
						if v149_:getCanBeSold() then
							local v150_ = v149_:getOwnerFarmId()
							if v150_ ~= nil then
								self.destructionAffectedFarmIds[v150_] = true
							end
							v149_:delete()
						end
					end
				elseif v145_.isPlaceable then
					local v151_ = v132_:getNodeObject(v144_)
					if v151_:destruct() then
						local v152_ = v151_:getOwnerFarmId()
						if v152_ ~= nil then
							self.destructionAffectedFarmIds[v152_] = true
						end
					end
				elseif v145_.isSplitShape then
					local v153_, _, v154_ = getWorldTranslation(getParent(v144_))
					local v155_ = g_farmlandManager:getOwnerIdAtWorldPosition(v153_, v154_)
					if v155_ ~= nil then
						self.destructionAffectedFarmIds[v155_] = true
					end
					g_treePlantManager:replaceWithTreeType(getParent(v144_), self.treeTypeIndex)
				end
				self.currentObjects[v144_] = nil
			end
		end
		self.objectCheckPending = false
	end
end

function Twister:baleOutsideCallback(node, x, y, z, distance, nx, ny, nz, subshapeIndex, shapeId, isLast)
	self.isBaleOutside = false
end

-- Local values: mission, object, splitTypeIndex, treeType
function Twister:onObjectCallback(transformId, subShapeIndex, isLast)
	local v160_ = g_currentMission
	if v160_ == nil then
		return false
	end
	if transformId ~= 0 then
		local v161_ = v160_:getNodeObject(transformId)
		if v161_ == nil or not v161_:isa(Bale) then
			if v161_ == nil or (not v161_:isa(Placeable) or (v161_.getCanBeDestructedByTwister == nil or not v161_:getCanBeDestructedByTwister())) then
				if getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) and not getIsSplitShapeSplit(transformId) then
					local v162_ = getSplitType(transformId)
					local v163_ = g_treePlantManager:getTreeTypeDescFromSplitType(v162_)
					if v163_ ~= nil and v163_.index ~= self.treeTypeIndex then
						self.foundObjects[transformId] = {
							["isSplitShape"] = true,
							["isBale"] = false,
							["isPlaceable"] = false
						}
					end
				end
			else
				self.foundObjects[transformId] = {
					["isSplitShape"] = false,
					["isBale"] = false,
					["isPlaceable"] = true
				}
			end
		else
			self.foundObjects[transformId] = {
				["isSplitShape"] = false,
				["isBale"] = true,
				["isPlaceable"] = false
			}
		end
	end
	if isLast then
		self:onFinishCallback()
	end
	return true
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
