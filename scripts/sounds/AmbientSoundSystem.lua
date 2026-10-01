AmbientSoundSystem = {}
local AmbientSoundSystem_mt = Class(AmbientSoundSystem)
g_xmlManager:addCreateSchemaFunction(function()
	AmbientSoundSystem.xmlSchema = XMLSchema.new("ambientSounds")
end)
g_xmlManager:addInitSchemaFunction(function()
	local schema = AmbientSoundSystem.xmlSchema
	schema:register(XMLValueType.STRING, "sound.ambient.comment(?)#v", "Comment used for managing xml file")
	local basePath = "sound.ambient.sample(?)"
	schema:register(XMLValueType.STRING, "sound.ambient.sample(?)" .. "#filename", "Sample filename")
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. "#probability", "Sample probability", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. "#positionTag", "Tag to attach the sound to a specific 3d position", "")
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. "#radius", "Outer radius for the 3d positioned sound", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. "#innerRadius", "Inner radius for the 3d positioned sound", 0)
	schema:register(XMLValueType.STRING, "sound.ambient.sample(?)" .. ".settings#audioGroup", "The audio group the sound will be assigned to", "ENVIRONMENT")
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#fadeInTime", "The fade in time in seconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#fadeOutTime", "The fade out time in seconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#minVolume", "The minVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#maxVolume", "The maxVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#indoorVolume", "The volume if the player is indoor or in a vehicle", 0.8)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".settings#minLoops", "The minimum number of loops played once a sound is triggered (0 means it will play one loop)", 1)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".settings#maxLoops", "The maximum number of loops played once a sound is triggered", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#minRetriggerDelaySeconds", "The minimum number of seconds until sound can be retriggred", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#maxRetriggerDelaySeconds", "The maximum number of seconds until the sound has to be retriggered", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#minPitch", "The min pitch", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#maxPitch", "The max pitch", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#minDelay", "The min delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#maxDelay", "The max delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#minLength", "The min length time in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".settings#maxLength", "The max length time in milliseconds", 0)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".settings#minTimeOfDay", "The min time of the day in minutes (Range: 0-1440)", 0)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".settings#maxTimeOfDay", "The max time of the day in minutes (Range: 0-1440)", 1440)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".settings#minDayOfYear", "The min day of the year (Range: 0-365)", 0)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".settings#maxDayOfYear", "The max day of the year (Range: 0-365)", 365)
	schema:register(XMLValueType.STRING, "sound.ambient.sample(?)" .. ".variation(?)#filename", "Sample filename")
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#probability", "Sample probability", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#fadeInTime", "The fade in time in seconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#fadeOutTime", "The fade out time in seconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#minVolume", "The minVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#maxVolume", "The maxVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#indoorVolume", "The volume if the player is indoor or in a vehicle", 0.8)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".variation(?)#minLoops", "The minimum number of loops played once a sound is triggered (0 means it will play one loop)", 1)
	schema:register(XMLValueType.INT, "sound.ambient.sample(?)" .. ".variation(?)#maxLoops", "The maximum number of loops played once a sound is triggered", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#minPitch", "The min pitch", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#maxPitch", "The max pitch", 1)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#minDelay", "The min delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#maxDelay", "The max delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#minLength", "The min length time in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, "sound.ambient.sample(?)" .. ".variation(?)#maxLength", "The max length time in milliseconds", 0)
	schema:register(XMLValueType.STRING, "sound.ambient3d#filename", "3d Ambient sound file")
	local surfacePath = "sound.surface.material(?)"
	schema:register(XMLValueType.INT, "sound.surface.material(?)" .. "#materialId", "Material id")
	schema:register(XMLValueType.STRING, "sound.surface.material(?)" .. "#name", "Material name")
	schema:register(XMLValueType.STRING, "sound.surface.material(?)" .. "#type", "Sample type")
	schema:register(XMLValueType.INT, "sound.surface.material(?)" .. "#loopCount", "Sample loop count")
	schema:register(XMLValueType.STRING, "sound.surface.material(?)" .. "#template", "Sample template")
	schema:registerAutoCompletionDataSource("sound.surface.material(?)" .. "#template", "$data/sounds/soundTemplates.xml", "soundTemplates.template#name")
	SoundManager.registerSampleXMLPaths(schema, "sound.cutting", "sample(?)")
	schema:register(XMLValueType.STRING, "sound.cutting.sample(?)#name", "Cutting sample name")
end)
function AmbientSoundSystem.new(soundPlayer, customMt)
	local self = setmetatable({}, customMt or AmbientSoundSystem_mt)
	self.soundPlayerId = nil
	if soundPlayer ~= nil then
		self.soundPlayerId = soundPlayer.soundPlayerId
	end
	self.samples = {}
	self.isDebugViewActive = false
	self.movingSounds = {}
	self.isDeleted = false
	self.conditionFlags = ConditionFlags.new()
	self.conditionFlags:registerModifier("inForest", nil)
	self.conditionFlags:registerModifier("nearWater", nil)
	self.conditionFlags:registerModifier("nearWall", nil)
	self.conditionFlags:registerModifier("underRoof", nil)
	self.conditionFlags:registerModifier("areaOpenField", nil)
	self.conditionFlags:registerModifier("areaCity", nil)
	self.conditionFlags:registerModifier("areaVillage", nil)
	self.conditionFlags:registerModifier("areaHarbor", nil)
	self.conditionFlags:registerModifier("areaIndustrial", nil)
	self.conditionFlags:registerModifier("areaOpenWater", nil)
	self.conditionFlags:registerModifier("spring", nil)
	self.conditionFlags:registerModifier("summer", nil)
	self.conditionFlags:registerModifier("autumn", nil)
	self.conditionFlags:registerModifier("winter", nil)
	self.conditionFlags:registerModifier("sun", nil)
	self.conditionFlags:registerModifier("cloudy", nil)
	self.conditionFlags:registerModifier("rain", nil)
	self.conditionFlags:registerModifier("snow", nil)
	self.conditionFlags:registerModifier("hail", nil)
	self.conditionFlags:registerModifier("inVehicle", nil)
	self.conditionFlags:registerModifier("outVehicle", nil)
	self.conditionFlags:registerModifier("isIndoor", nil)
	self.conditionFlags:registerModifier("windSpeedLow", nil)
	self.conditionFlags:registerModifier("windSpeedMedium", nil)
	self.conditionFlags:registerModifier("windSpeedHigh", nil)
	self.conditionFlags:registerXMLPaths(AmbientSoundSystem.xmlSchema, "sound.ambient.sample(?)")
	return self
end
function AmbientSoundSystem:delete()
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	self:unloadAmbientSounds()
	self.conditionFlags:delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsAmbientSoundSystemToggleDebugView")
	removeConsoleCommand("gsAmbientSoundSystemReload")
end
function AmbientSoundSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	if self.soundPlayerId == nil then
		return false
	end
	local xmlFilename = Utils.getFilename(getXMLString(mapXmlFile, "map.sounds#filename"), baseDirectory)
	if xmlFilename == nil then
		return false
	elseif not fileExists(xmlFilename) then
		Logging.warning("AmbientSoundSystem could not load configuration xml file '%s'!", xmlFilename)
		return false
	else
		self.baseDirectory = baseDirectory
		self.xmlFilename = xmlFilename
		addConsoleCommand("gsAmbientSoundSystemToggleDebugView", "Toggles the ambient sound system debug view", "consoleCommandToggleDebugView", self)
		addConsoleCommand("gsAmbientSoundSystemReload", "Reloads the ambient sound system", "consoleCommandReload", self)
		return self:loadFromConfigFile()
	end
end
function AmbientSoundSystem:loadFromConfigFile()
	self.isDeleted = false
	local xmlFile = XMLFile.load("Ambient Sounds", self.xmlFilename, AmbientSoundSystem.xmlSchema)
	if xmlFile == nil then
		Logging.xmlWarning(xmlFile, "AmbientSoundSystem could not load configuration xml file!")
		return false
	else
		for _, sampleKey in xmlFile:iterator("sound.ambient.sample") do
			local filename = xmlFile:getValue(sampleKey .. "#filename")
			local probability = xmlFile:getValue(sampleKey .. "#probability", 1)
			local positionTag = xmlFile:getValue(sampleKey .. "#positionTag", "")
			local radius = xmlFile:getValue(sampleKey .. "#radius", 0)
			local innerRadius = xmlFile:getValue(sampleKey .. "#innerRadius", 0)
			local audioGroup = xmlFile:getValue(sampleKey .. ".settings#audioGroup", "ENVIRONMENT")
			local fadeInTime = xmlFile:getValue(sampleKey .. ".settings#fadeInTime", 0)
			local fadeOutTime = xmlFile:getValue(sampleKey .. ".settings#fadeOutTime", 0)
			local minVolume = xmlFile:getValue(sampleKey .. ".settings#minVolume", 1)
			local maxVolume = xmlFile:getValue(sampleKey .. ".settings#maxVolume", 1)
			local indoorVolumeFactor = xmlFile:getValue(sampleKey .. ".settings#indoorVolume", 0.8)
			local minLoops = xmlFile:getValue(sampleKey .. ".settings#minLoops", 1)
			local maxLoops = xmlFile:getValue(sampleKey .. ".settings#maxLoops", 1)
			local minRetriggerDelay = xmlFile:getValue(sampleKey .. ".settings#minRetriggerDelaySeconds", 0)
			local maxRetriggerDelay = xmlFile:getValue(sampleKey .. ".settings#maxRetriggerDelaySeconds", 0)
			local minPitch = xmlFile:getValue(sampleKey .. ".settings#minPitch", 1)
			local maxPitch = xmlFile:getValue(sampleKey .. ".settings#maxPitch", 1)
			local minDelay = xmlFile:getValue(sampleKey .. ".settings#minDelay", 0)
			local maxDelay = xmlFile:getValue(sampleKey .. ".settings#maxDelay", 0)
			local minLength = xmlFile:getValue(sampleKey .. ".settings#minLength", 0)
			local maxLength = xmlFile:getValue(sampleKey .. ".settings#maxLength", 0)
			local minTimeOfDay = xmlFile:getValue(sampleKey .. ".settings#minTimeOfDay", 0)
			local maxTimeOfDay = xmlFile:getValue(sampleKey .. ".settings#maxTimeOfDay", 1440)
			local minDayOfYear = xmlFile:getValue(sampleKey .. ".settings#minDayOfYear", 0)
			local maxDayOfYear = xmlFile:getValue(sampleKey .. ".settings#maxDayOfYear", 365)
			local audioGroupId = AudioGroup.getAudioGroupIndexByName(audioGroup)
			if audioGroupId == nil then
				audioGroupId = AudioGroup.ENVIRONMENT
			end
			filename = Utils.getFilename(filename, self.baseDirectory)
			local requiredFlags, preventFlags = self.conditionFlags:loadFlagsFromXMLFile(xmlFile, sampleKey)
			local sampleId = ambientSoundsAddSample(self.soundPlayerId, audioGroupId, minRetriggerDelay, maxRetriggerDelay, requiredFlags, preventFlags, minTimeOfDay, maxTimeOfDay, minDayOfYear, maxDayOfYear, positionTag or "", radius or 0, innerRadius or 0)
			local variationId = ambientSoundsAddSampleVariation(self.soundPlayerId, sampleId, filename, probability)
			ambientSoundsSampleSetIndoorVolumeFactor(self.soundPlayerId, sampleId, variationId, indoorVolumeFactor)
			ambientSoundsSampleSetFadeInOutTime(self.soundPlayerId, sampleId, variationId, fadeInTime, fadeOutTime)
			ambientSoundsSampleSetMinMaxVolume(self.soundPlayerId, sampleId, variationId, minVolume, maxVolume)
			ambientSoundsSampleSetMinMaxLoops(self.soundPlayerId, sampleId, variationId, minLoops, maxLoops)
			ambientSoundsSampleSetMinMaxPitch(self.soundPlayerId, sampleId, variationId, minPitch, maxPitch)
			ambientSoundsSampleSetMinMaxDelay(self.soundPlayerId, sampleId, variationId, minDelay, maxDelay)
			ambientSoundsSampleSetMinMaxLength(self.soundPlayerId, sampleId, variationId, minLength, maxLength)
			for _, variationKey in xmlFile:iterator(sampleKey .. ".variation") do
				local varFilename = xmlFile:getValue(variationKey .. "#filename")
				local varProbability = xmlFile:getValue(variationKey .. "#probability", 1)
				local varFadeInTime = xmlFile:getValue(variationKey .. "#fadeInTime", fadeInTime)
				local varFadeOutTime = xmlFile:getValue(variationKey .. "#fadeOutTime", fadeOutTime)
				local varMinVolume = xmlFile:getValue(variationKey .. "#minVolume", minVolume)
				local varMaxVolume = xmlFile:getValue(variationKey .. "#maxVolume", maxVolume)
				local varIndoorVolumeFactor = xmlFile:getValue(variationKey .. "#indoorVolume", indoorVolumeFactor)
				local varMinLoops = xmlFile:getValue(variationKey .. "#minLoops", minLoops)
				local varMaxLoops = xmlFile:getValue(variationKey .. "#maxLoops", maxLoops)
				local varMinPitch = xmlFile:getValue(variationKey .. "#minPitch", minPitch)
				local varMaxPitch = xmlFile:getValue(variationKey .. "#maxPitch", maxPitch)
				local varMinDelay = xmlFile:getValue(variationKey .. "#minDelay", minDelay)
				local varMaxDelay = xmlFile:getValue(variationKey .. "#maxDelay", maxDelay)
				local varMinLength = xmlFile:getValue(variationKey .. "#minLength", minLength)
				local varMaxLength = xmlFile:getValue(variationKey .. "#maxLength", maxLength)
				varFilename = Utils.getFilename(varFilename, self.baseDirectory)
				variationId = ambientSoundsAddSampleVariation(self.soundPlayerId, sampleId, varFilename, varProbability)
				ambientSoundsSampleSetIndoorVolumeFactor(self.soundPlayerId, sampleId, variationId, varIndoorVolumeFactor)
				ambientSoundsSampleSetFadeInOutTime(self.soundPlayerId, sampleId, variationId, varFadeInTime, varFadeOutTime)
				ambientSoundsSampleSetMinMaxVolume(self.soundPlayerId, sampleId, variationId, varMinVolume, varMaxVolume)
				ambientSoundsSampleSetMinMaxLoops(self.soundPlayerId, sampleId, variationId, varMinLoops, varMaxLoops)
				ambientSoundsSampleSetMinMaxPitch(self.soundPlayerId, sampleId, variationId, varMinPitch, varMaxPitch)
				ambientSoundsSampleSetMinMaxDelay(self.soundPlayerId, sampleId, variationId, varMinDelay, varMaxDelay)
				ambientSoundsSampleSetMinMaxLength(self.soundPlayerId, sampleId, variationId, varMinLength, varMaxLength)
			end
			table.insert(self.samples, { filename = filename, audioGroupId = audioGroupId, requiredFlags = requiredFlags, preventFlags = preventFlags, minTimeOfDay = minTimeOfDay, maxTimeOfDay = maxTimeOfDay, minDayOfYear = minDayOfYear, maxDayOfYear = maxDayOfYear })
		end
		local filename = xmlFile:getValue("sound.ambient3d#filename")
		if filename ~= nil then
			local sound3DFilename = Utils.getFilename(filename, self.baseDirectory)
			self.loadRequestId = g_i3DManager:loadI3DFileAsync(sound3DFilename, true, false, AmbientSoundSystem.sound3DFileLoaded, self, nil)
		end
		xmlFile:delete()
		g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.onWeatherChanged, self)
		g_messageCenter:subscribe(MessageType.OWN_PLAYER_ENTERED, self.onPlayerEntered, self)
		g_messageCenter:subscribe(MessageType.OWN_PLAYER_LEFT, self.onPlayerLeft, self)
		return true
	end
end
function AmbientSoundSystem:sound3DFileLoaded(i3dNode, failedReason, args)
	if i3dNode ~= nil and i3dNode ~= 0 then
		if self.isDeleted or self.sound3DRootNode ~= nil then
			delete(i3dNode)
			return
		end
		self.sound3DRootNode = i3dNode
		link(getRootNode(), i3dNode)
	end
	self.loadRequestId = nil
end
function AmbientSoundSystem:addMovingSound(node)
	local numChildren = getNumOfChildren(node)
	if numChildren < 2 or 3 < numChildren then
		Logging.devWarning("AmbientSoundSystem:addMovingSound(): Invalid number of children given for node '%s'", getName(node))
		return
	end
	local spline = getChildAt(node, 0)
	local transformNode = getChildAt(node, 1)
	if not getHasClassId(getGeometry(spline), ClassIds.SPLINE) then
		Logging.error("AmbientsoundSystem:addMovingSound(): First child '%s' of given node '%s' is not a spline!", getName(spline), getName(node))
		return
	else
		setVisibility(spline, false)
		local splineLength = getSplineLength(spline)
		local eps = 0.01 / splineLength
		local modifiers = {}
		if numChildren == 3 then
			local modifiersNode = getChildAt(node, 2)
			for i = 0, getNumOfChildren(modifiersNode) - 1 do
				local modifierNode = getChildAt(modifiersNode, i)
				local startNode = getChildAt(modifierNode, 0)
				local endNode = getChildAt(modifierNode, 1)
				local sx, sy, sz = getWorldTranslation(startNode)
				local _, _, _, startTime = getClosestSplinePosition(spline, sx, sy, sz, eps)
				local ex, ey, ez = getWorldTranslation(endNode)
				local _, _, _, endTime = getClosestSplinePosition(spline, ex, ey, ez, eps)
				if endTime < startTime then
					endTime = startTime
					startTime = endTime
					ex = sx
					ey = sy
					ez = sz
					sx = ex
					sy = ey
					sz = ez
				end
				local rangeScale = tonumber(getUserAttribute(modifierNode, "rangeScale"))
				local fadeDistance = tonumber(getUserAttribute(modifierNode, "fadeDistance"))
				local fadeDistanceTime = fadeDistance / splineLength
				local startTimeFadeEnd = startTime + fadeDistanceTime
				local endTimeFadeStart = endTime - fadeDistanceTime
				table.insert(modifiers, { startTime = startTime, startTimeFadeEnd = startTimeFadeEnd, endTime = endTime, endTimeFadeStart = endTimeFadeStart, rangeScale = rangeScale, fadeDistance = fadeDistance })
			end
		end
		table.sort(modifiers, function(a, b)
			return a.startTime < b.startTime
		end)
		local sounds = {}
		for i = 0, getNumOfChildren(transformNode) - 1 do
			local soundNode = getChildAt(transformNode, i)
			if not getHasClassId(soundNode, ClassIds.AUDIO_SOURCE) then
				Logging.warning("AmbientsoundSystem:addMovingSound(): Child '%s' of transform '%s' is not an audio source", getName(soundNode), I3DUtil.getNodePath(transformNode))
			else
				local x, y, z = getTranslation(soundNode)
				if x ~= 0 or y ~= 0 or z ~= 0 then
					Logging.warning("AmbientsoundSystem:addMovingSound(): Child '%s' of transform '%s' is offset (translation not 0 0 0)", getName(soundNode), I3DUtil.getNodePath(transformNode))
				else
					local innerRange = getAudioSourceInnerRange(soundNode)
					local outerRange = getAudioSourceRange(soundNode)
					table.insert(sounds, { node = soundNode, innerRange = innerRange, outerRange = outerRange })
				end
			end
		end
		local movingSoundEntry = { spline = spline, node = transformNode, eps = eps, sounds = sounds, modifiers = modifiers }
		table.insert(self.movingSounds, movingSoundEntry)
		return movingSoundEntry
	end
end
function AmbientSoundSystem:removeMovingSound(movingSoundEntry)
	return table.removeElement(self.movingSounds, movingSoundEntry)
end
function AmbientSoundSystem:unloadAmbientSounds()
	if self.soundPlayerId ~= nil then
		ambientSoundsRemoveAllSamples(self.soundPlayerId)
		self.samples = {}
	end
	if self.sound3DRootNode ~= nil then
		delete(self.sound3DRootNode)
		self.sound3DRootNode = nil
	end
	self.movingSounds = {}
	self.isDeleted = true
end
function AmbientSoundSystem:update(dt)
	if self.soundPlayerId ~= nil then
		local environment = g_currentMission.environment
		if environment ~= nil then
			local minuteOfDay = environment:getMinuteOfDay()
			local dayOfYear = math.clamp(environment:getDayOfYear(), 0, 365)
			ambientSoundsSetTimeAndDay(self.soundPlayerId, minuteOfDay, dayOfYear)
			self:updateMask()
			local mask = self.conditionFlags:getMask()
			ambientSoundsUpdate(self.soundPlayerId, dt, mask)
		end
	end
	local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	for _, movingSound in ipairs(self.movingSounds) do
		local sx, sy, sz, t = getClosestSplinePosition(movingSound.spline, x, y, z, movingSound.eps)
		setWorldTranslation(movingSound.node, sx, sy, sz)
		local rangeScale = 1
		for _, modifier in ipairs(movingSound.modifiers) do
			if modifier.startTime <= t and t <= modifier.endTime then
				local alpha = 1
				if t <= modifier.startTimeFadeEnd then
					alpha = 1 - (modifier.startTimeFadeEnd - t) / (modifier.startTimeFadeEnd - modifier.startTime)
				end
				if modifier.endTimeFadeStart < t then
					alpha = (modifier.endTime - t) / (modifier.endTime - modifier.endTimeFadeStart)
					rangeScale = MathUtil.lerp(1, modifier.rangeScale, alpha)
					break
				else
					break
				end
			end
		end
		if movingSound.lastScale ~= rangeScale then
			for _, sound in ipairs(movingSound.sounds) do
				setAudioSourceInnerRange(sound.node, sound.innerRange * rangeScale)
				setAudioSourceRange(sound.node, sound.outerRange * rangeScale)
			end
			movingSound.lastScale = rangeScale
		end
		if self.isDebugViewActive then
			DebugPoint.renderAtPosition(sx, sy, sz, nil, false, string.format("%s (RangeScale=%.3f)", getName(movingSound.node), rangeScale))
			for _, modifier in ipairs(movingSound.modifiers) do
				local debugX = nil
				local debugY = nil
				local debugZ = nil
				debugX, debugY, debugZ = getSplinePosition(movingSound.spline, modifier.startTime)
				DebugFlag.renderAtPosition(debugX, debugY, debugZ, 1, 0, DebugUtil.tableToColor(modifier), "startTime")
				debugX, debugY, debugZ = getSplinePosition(movingSound.spline, modifier.startTimeFadeEnd)
				DebugFlag.renderAtPosition(debugX, debugY, debugZ, 1, 0, DebugUtil.tableToColor(modifier), "startTimeFadeEnd")
				debugX, debugY, debugZ = getSplinePosition(movingSound.spline, modifier.endTime)
				DebugFlag.renderAtPosition(debugX, debugY, debugZ, 1, 0, DebugUtil.tableToColor(modifier), "endTime")
				debugX, debugY, debugZ = getSplinePosition(movingSound.spline, modifier.endTimeFadeStart)
				DebugFlag.renderAtPosition(debugX, debugY, debugZ, 1, 0, DebugUtil.tableToColor(modifier), "endTimeFadeStart")
			end
		end
	end
end
function AmbientSoundSystem:updateMask()
	local conditionFlags = self.conditionFlags
	local mission = g_currentMission
	local weights = mission.environmentAreaSystem:getAreaWeights()
	local isOpenField = 0.5 < weights.areaTypeWeights[AreaType.OPEN_FIELD]
	local isInForest = isOpenField and 0.5 < weights.isInForestWeight
	if isInForest then
		isOpenField = false
	end
	conditionFlags:setModifierValue("inForest", isInForest)
	conditionFlags:setModifierValue("nearWater", 0.5 < weights.isNearWaterWeight)
	conditionFlags:setModifierValue("nearWall", 0.5 < weights.isNearWallWeight)
	conditionFlags:setModifierValue("underRoof", 0.5 < weights.isUnderRoofWeight)
	conditionFlags:setModifierValue("areaOpenField", isOpenField)
	conditionFlags:setModifierValue("areaCity", 0.5 < weights.areaTypeWeights[AreaType.CITY])
	conditionFlags:setModifierValue("areaVillage", 0.5 < weights.areaTypeWeights[AreaType.VILLAGE])
	conditionFlags:setModifierValue("areaHarbor", 0.5 < weights.areaTypeWeights[AreaType.HARBOR])
	conditionFlags:setModifierValue("areaIndustrial", 0.5 < weights.areaTypeWeights[AreaType.INDUSTRIAL])
	conditionFlags:setModifierValue("areaOpenWater", 0.5 < weights.areaTypeWeights[AreaType.OPEN_WATER])
	local environment = mission.environment
	local weather = environment.weather
	local isRaining = 0 < weather:getRainFallScale()
	local isSnowing = 0 < weather:getSnowFallScale()
	local isHailing = weather:getIsHailing()
	conditionFlags:setModifierValue("rain", isRaining)
	conditionFlags:setModifierValue("snow", isSnowing)
	conditionFlags:setModifierValue("hail", isHailing)
	local _, _, windVelocity = weather.windUpdater:getCurrentValues()
	conditionFlags:setModifierValue("windSpeedLow", windVelocity < 6)
	conditionFlags:setModifierValue("windSpeedMedium", 6 <= windVelocity and windVelocity < 20)
	conditionFlags:setModifierValue("windSpeedHigh", false)
	local season = SeasonPeriod.getSeason(environment.currentVisualPeriod)
	conditionFlags:setModifierValue("spring", season == Season.SPRING)
	conditionFlags:setModifierValue("summer", season == Season.SUMMER)
	conditionFlags:setModifierValue("autumn", season == Season.AUTUMN)
	conditionFlags:setModifierValue("winter", season == Season.WINTER)
end
function AmbientSoundSystem:setIsEnabled(isEnabled)
	if self.soundPlayerId ~= nil then
		ambientSoundsSetEnabled(self.soundPlayerId, isEnabled)
	end
end
function AmbientSoundSystem:setIsIndoor(isIndoor)
	local conditionFlags = self.conditionFlags
	conditionFlags:setModifierValue("isIndoor", isIndoor)
	if self.soundPlayerId ~= nil then
		ambientSoundsSetIsIndoor(self.soundPlayerId, isIndoor)
	end
end
function AmbientSoundSystem:onWeatherChanged(weatherObject)
	local typeIndex = weatherObject.weatherType
	local conditionFlags = self.conditionFlags
	conditionFlags:setModifierValue("sun", typeIndex == WeatherType.SUN)
	conditionFlags:setModifierValue("cloudy", typeIndex == WeatherType.CLOUDY)
end
function AmbientSoundSystem:onPlayerEntered()
	local conditionFlags = self.conditionFlags
	conditionFlags:setModifierValue("outVehicle", true)
	conditionFlags:setModifierValue("inVehicle", false)
end
function AmbientSoundSystem:onPlayerLeft()
	local conditionFlags = self.conditionFlags
	conditionFlags:setModifierValue("outVehicle", false)
	conditionFlags:setModifierValue("inVehicle", true)
end
function AmbientSoundSystem:draw()
	if self.isDebugViewActive then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		renderText(0.1, 0.72, getCorrectTextSize(0.014), "Possible active ambient sounds:")
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.7, 0.72, getCorrectTextSize(0.014), "Modifiers:")
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local posY = 0.7
		local textSize = getCorrectTextSize(0.012)
		local textOffset = getCorrectTextSize(0.001)
		for _, sample in ipairs(self.samples) do
			local match = self:isSamplePossible(sample)
			if match then
				renderText(0.1, posY, textSize, AudioGroup.getAudioGroupNameByIndex(sample.audioGroupId))
				renderText(0.2, posY, textSize, sample.filename)
				posY = posY - textSize - textOffset
			end
		end
		posY = self.conditionFlags:drawDebug(0.7, 0.72)
		posY = posY - textSize - textOffset
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.7, posY, textSize, "time of day: ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.7, posY, textSize, tostring(g_currentMission.environment:getMinuteOfDay()))
		posY = posY - textSize - textOffset
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.7, posY, textSize, "day of year: ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.7, posY, textSize, tostring(g_currentMission.environment:getDayOfYear()))
	end
end
function AmbientSoundSystem:consoleCommandReload()
	self:unloadAmbientSounds()
	self:loadFromConfigFile()
end
function AmbientSoundSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive
	local mission = g_currentMission
	if self.isDebugViewActive then
		mission:addDrawable(self)
	else
		mission:removeDrawable(self)
	end
	for _, movingSound in ipairs(self.movingSounds) do
		setVisibility(movingSound.spline, self.isDebugViewActive)
	end
end
function AmbientSoundSystem:isSamplePossible(sample)
	local mask = self.conditionFlags:getMask()
	local match = false
	if bit32.band(mask, sample.preventFlags) == 0 then
		match = bit32.band(mask, sample.requiredFlags) == sample.requiredFlags
	end
	if not match then
		return false
	end
	local environment = g_currentMission.environment
	local minuteOfDay = environment:getMinuteOfDay()
	local minTimeOfDay = sample.minTimeOfDay
	local maxTimeOfDay = sample.maxTimeOfDay
	if MathUtil.getIsOutOfBounds(minuteOfDay, minTimeOfDay, maxTimeOfDay) then
		return false
	end
	local dayOfYear = environment:getDayOfYear()
	local minDayOfYear = sample.minDayOfYear
	local maxDayOfYear = sample.maxDayOfYear
	if MathUtil.getIsOutOfBounds(dayOfYear, minDayOfYear, maxDayOfYear) then
		return false
	else
		return true
	end
end
