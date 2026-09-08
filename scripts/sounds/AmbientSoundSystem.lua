-- Local values: AmbientSoundSystem_mt
AmbientSoundSystem = {}
local AmbientSoundSystem_mt = Class(AmbientSoundSystem)
g_xmlManager:addCreateSchemaFunction(function()
	AmbientSoundSystem.xmlSchema = XMLSchema.new("ambientSounds")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = AmbientSoundSystem.xmlSchema
	v2_:register(XMLValueType.STRING, "sound.ambient.comment(?)#v", "Comment used for managing xml file")
	v2_:register(XMLValueType.STRING, "sound.ambient.sample(?)#filename", "Sample filename")
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?)#probability", "Sample probability", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?)#positionTag", "Tag to attach the sound to a specific 3d position", "")
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?)#radius", "Outer radius for the 3d positioned sound", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?)#innerRadius", "Inner radius for the 3d positioned sound", 0)
	v2_:register(XMLValueType.STRING, "sound.ambient.sample(?).settings#audioGroup", "The audio group the sound will be assigned to", "ENVIRONMENT")
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#fadeInTime", "The fade in time in seconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#fadeOutTime", "The fade out time in seconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#minVolume", "The minVolume if the player is outdoor", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#maxVolume", "The maxVolume if the player is outdoor", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#indoorVolume", "The volume if the player is indoor or in a vehicle", 0.8)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).settings#minLoops", "The minimum number of loops played once a sound is triggered (0 means it will play one loop)", 1)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).settings#maxLoops", "The maximum number of loops played once a sound is triggered", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#minRetriggerDelaySeconds", "The minimum number of seconds until sound can be retriggred", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#maxRetriggerDelaySeconds", "The maximum number of seconds until the sound has to be retriggered", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#minPitch", "The min pitch", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#maxPitch", "The max pitch", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#minDelay", "The min delay in milliseconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#maxDelay", "The max delay in milliseconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#minLength", "The min length time in milliseconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).settings#maxLength", "The max length time in milliseconds", 0)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).settings#minTimeOfDay", "The min time of the day in minutes (Range: 0-1440)", 0)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).settings#maxTimeOfDay", "The max time of the day in minutes (Range: 0-1440)", 1440)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).settings#minDayOfYear", "The min day of the year (Range: 0-365)", 0)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).settings#maxDayOfYear", "The max day of the year (Range: 0-365)", 365)
	v2_:register(XMLValueType.STRING, "sound.ambient.sample(?).variation(?)#filename", "Sample filename")
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#probability", "Sample probability", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#fadeInTime", "The fade in time in seconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#fadeOutTime", "The fade out time in seconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#minVolume", "The minVolume if the player is outdoor", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#maxVolume", "The maxVolume if the player is outdoor", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#indoorVolume", "The volume if the player is indoor or in a vehicle", 0.8)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).variation(?)#minLoops", "The minimum number of loops played once a sound is triggered (0 means it will play one loop)", 1)
	v2_:register(XMLValueType.INT, "sound.ambient.sample(?).variation(?)#maxLoops", "The maximum number of loops played once a sound is triggered", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#minPitch", "The min pitch", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#maxPitch", "The max pitch", 1)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#minDelay", "The min delay in milliseconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#maxDelay", "The max delay in milliseconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#minLength", "The min length time in milliseconds", 0)
	v2_:register(XMLValueType.FLOAT, "sound.ambient.sample(?).variation(?)#maxLength", "The max length time in milliseconds", 0)
	v2_:register(XMLValueType.STRING, "sound.ambient3d#filename", "3d Ambient sound file")
	v2_:register(XMLValueType.INT, "sound.surface.material(?)#materialId", "Material id")
	v2_:register(XMLValueType.STRING, "sound.surface.material(?)#name", "Material name")
	v2_:register(XMLValueType.STRING, "sound.surface.material(?)#type", "Sample type")
	v2_:register(XMLValueType.INT, "sound.surface.material(?)#loopCount", "Sample loop count")
	v2_:register(XMLValueType.STRING, "sound.surface.material(?)#template", "Sample template")
	v2_:registerAutoCompletionDataSource("sound.surface.material(?)#template", "$data/sounds/soundTemplates.xml", "soundTemplates.template#name")
	SoundManager.registerSampleXMLPaths(v2_, "sound.cutting", "sample(?)")
	v2_:register(XMLValueType.STRING, "sound.cutting.sample(?)#name", "Cutting sample name")
end)

-- Upvalues: AmbientSoundSystem_mt
-- Local values: self
function AmbientSoundSystem.new(soundPlayer, customMt)
	-- upvalues: (copy) AmbientSoundSystem_mt
	local v5_ = customMt or AmbientSoundSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.soundPlayerId = nil
	if soundPlayer ~= nil then
		v6_.soundPlayerId = soundPlayer.soundPlayerId
	end
	v6_.samples = {}
	v6_.isDebugViewActive = false
	v6_.movingSounds = {}
	v6_.isDeleted = false
	v6_.conditionFlags = ConditionFlags.new()
	v6_.conditionFlags:registerModifier("inForest", nil)
	v6_.conditionFlags:registerModifier("nearWater", nil)
	v6_.conditionFlags:registerModifier("nearWall", nil)
	v6_.conditionFlags:registerModifier("underRoof", nil)
	v6_.conditionFlags:registerModifier("areaOpenField", nil)
	v6_.conditionFlags:registerModifier("areaCity", nil)
	v6_.conditionFlags:registerModifier("areaVillage", nil)
	v6_.conditionFlags:registerModifier("areaHarbor", nil)
	v6_.conditionFlags:registerModifier("areaIndustrial", nil)
	v6_.conditionFlags:registerModifier("areaOpenWater", nil)
	v6_.conditionFlags:registerModifier("spring", nil)
	v6_.conditionFlags:registerModifier("summer", nil)
	v6_.conditionFlags:registerModifier("autumn", nil)
	v6_.conditionFlags:registerModifier("winter", nil)
	v6_.conditionFlags:registerModifier("sun", nil)
	v6_.conditionFlags:registerModifier("cloudy", nil)
	v6_.conditionFlags:registerModifier("rain", nil)
	v6_.conditionFlags:registerModifier("snow", nil)
	v6_.conditionFlags:registerModifier("hail", nil)
	v6_.conditionFlags:registerModifier("inVehicle", nil)
	v6_.conditionFlags:registerModifier("outVehicle", nil)
	v6_.conditionFlags:registerModifier("isIndoor", nil)
	v6_.conditionFlags:registerModifier("windSpeedLow", nil)
	v6_.conditionFlags:registerModifier("windSpeedMedium", nil)
	v6_.conditionFlags:registerModifier("windSpeedHigh", nil)
	v6_.conditionFlags:registerXMLPaths(AmbientSoundSystem.xmlSchema, "sound.ambient.sample(?)")
	return v6_
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

-- Local values: xmlFilename
function AmbientSoundSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	if self.soundPlayerId == nil then
		return false
	end
	local v11_ = Utils.getFilename(getXMLString(mapXmlFile, "map.sounds#filename"), baseDirectory)
	if v11_ == nil then
		return false
	end
	if not fileExists(v11_) then
		Logging.warning("AmbientSoundSystem could not load configuration xml file \'%s\'!", v11_)
		return false
	end
	self.baseDirectory = baseDirectory
	self.xmlFilename = v11_
	addConsoleCommand("gsAmbientSoundSystemToggleDebugView", "Toggles the ambient sound system debug view", "consoleCommandToggleDebugView", self)
	addConsoleCommand("gsAmbientSoundSystemReload", "Reloads the ambient sound system", "consoleCommandReload", self)
	return self:loadFromConfigFile()
end

-- Local values: xmlFile, _, sampleKey, filename, probability, positionTag, radius, innerRadius, audioGroup, fadeInTime, fadeOutTime, minVolume, maxVolume, indoorVolumeFactor, minLoops, maxLoops, minRetriggerDelay, maxRetriggerDelay, minPitch, maxPitch, minDelay, maxDelay, minLength, maxLength, minTimeOfDay, maxTimeOfDay, minDayOfYear, maxDayOfYear, audioGroupId, requiredFlags, preventFlags, sampleId, variationId, _, variationKey, varFilename, varProbability, varFadeInTime, varFadeOutTime, varMinVolume, varMaxVolume, varIndoorVolumeFactor, varMinLoops, varMaxLoops, varMinPitch, varMaxPitch, varMinDelay, varMaxDelay, varMinLength, varMaxLength, filename, sound3DFilename
function AmbientSoundSystem:loadFromConfigFile()
	self.isDeleted = false
	local v13_ = XMLFile.load("Ambient Sounds", self.xmlFilename, AmbientSoundSystem.xmlSchema)
	if v13_ == nil then
		Logging.xmlWarning(v13_, "AmbientSoundSystem could not load configuration xml file!")
		return false
	end
	for _, v14_ in v13_:iterator("sound.ambient.sample") do
		local v15_ = v13_:getValue(v14_ .. "#filename")
		local v16_ = v13_:getValue(v14_ .. "#probability", 1)
		local v17_ = v13_:getValue(v14_ .. "#positionTag", "")
		local v18_ = v13_:getValue(v14_ .. "#radius", 0)
		local v19_ = v13_:getValue(v14_ .. "#innerRadius", 0)
		local v20_ = v13_:getValue(v14_ .. ".settings#audioGroup", "ENVIRONMENT")
		local v21_ = v13_:getValue(v14_ .. ".settings#fadeInTime", 0)
		local v22_ = v13_:getValue(v14_ .. ".settings#fadeOutTime", 0)
		local v23_ = v13_:getValue(v14_ .. ".settings#minVolume", 1)
		local v24_ = v13_:getValue(v14_ .. ".settings#maxVolume", 1)
		local v25_ = v13_:getValue(v14_ .. ".settings#indoorVolume", 0.8)
		local v26_ = v13_:getValue(v14_ .. ".settings#minLoops", 1)
		local v27_ = v13_:getValue(v14_ .. ".settings#maxLoops", 1)
		local v28_ = v13_:getValue(v14_ .. ".settings#minRetriggerDelaySeconds", 0)
		local v29_ = v13_:getValue(v14_ .. ".settings#maxRetriggerDelaySeconds", 0)
		local v30_ = v13_:getValue(v14_ .. ".settings#minPitch", 1)
		local v31_ = v13_:getValue(v14_ .. ".settings#maxPitch", 1)
		local v32_ = v13_:getValue(v14_ .. ".settings#minDelay", 0)
		local v33_ = v13_:getValue(v14_ .. ".settings#maxDelay", 0)
		local v34_ = v13_:getValue(v14_ .. ".settings#minLength", 0)
		local v35_ = v13_:getValue(v14_ .. ".settings#maxLength", 0)
		local v36_ = v13_:getValue(v14_ .. ".settings#minTimeOfDay", 0)
		local v37_ = v13_:getValue(v14_ .. ".settings#maxTimeOfDay", 1440)
		local v38_ = v13_:getValue(v14_ .. ".settings#minDayOfYear", 0)
		local v39_ = v13_:getValue(v14_ .. ".settings#maxDayOfYear", 365)
		local v40_ = AudioGroup.getAudioGroupIndexByName(v20_)
		if v40_ == nil then
			v40_ = AudioGroup.ENVIRONMENT
		end
		local v41_ = Utils.getFilename(v15_, self.baseDirectory)
		local v42_, v43_ = self.conditionFlags:loadFlagsFromXMLFile(v13_, v14_)
		local v44_ = ambientSoundsAddSample(self.soundPlayerId, v40_, v28_, v29_, v42_, v43_, v36_, v37_, v38_, v39_, v17_ or "", v18_ or 0, v19_ or 0)
		local v45_ = ambientSoundsAddSampleVariation(self.soundPlayerId, v44_, v41_, v16_)
		ambientSoundsSampleSetIndoorVolumeFactor(self.soundPlayerId, v44_, v45_, v25_)
		ambientSoundsSampleSetFadeInOutTime(self.soundPlayerId, v44_, v45_, v21_, v22_)
		ambientSoundsSampleSetMinMaxVolume(self.soundPlayerId, v44_, v45_, v23_, v24_)
		ambientSoundsSampleSetMinMaxLoops(self.soundPlayerId, v44_, v45_, v26_, v27_)
		ambientSoundsSampleSetMinMaxPitch(self.soundPlayerId, v44_, v45_, v30_, v31_)
		ambientSoundsSampleSetMinMaxDelay(self.soundPlayerId, v44_, v45_, v32_, v33_)
		ambientSoundsSampleSetMinMaxLength(self.soundPlayerId, v44_, v45_, v34_, v35_)
		for _, v46_ in v13_:iterator(v14_ .. ".variation") do
			local v47_ = v13_:getValue(v46_ .. "#filename")
			local v48_ = v13_:getValue(v46_ .. "#probability", 1)
			local v49_ = v13_:getValue(v46_ .. "#fadeInTime", v21_)
			local v50_ = v13_:getValue(v46_ .. "#fadeOutTime", v22_)
			local v51_ = v13_:getValue(v46_ .. "#minVolume", v23_)
			local v52_ = v13_:getValue(v46_ .. "#maxVolume", v24_)
			local v53_ = v13_:getValue(v46_ .. "#indoorVolume", v25_)
			local v54_ = v13_:getValue(v46_ .. "#minLoops", v26_)
			local v55_ = v13_:getValue(v46_ .. "#maxLoops", v27_)
			local v56_ = v13_:getValue(v46_ .. "#minPitch", v30_)
			local v57_ = v13_:getValue(v46_ .. "#maxPitch", v31_)
			local v58_ = v13_:getValue(v46_ .. "#minDelay", v32_)
			local v59_ = v13_:getValue(v46_ .. "#maxDelay", v33_)
			local v60_ = v13_:getValue(v46_ .. "#minLength", v34_)
			local v61_ = v13_:getValue(v46_ .. "#maxLength", v35_)
			local v62_ = Utils.getFilename(v47_, self.baseDirectory)
			local v63_ = ambientSoundsAddSampleVariation(self.soundPlayerId, v44_, v62_, v48_)
			ambientSoundsSampleSetIndoorVolumeFactor(self.soundPlayerId, v44_, v63_, v53_)
			ambientSoundsSampleSetFadeInOutTime(self.soundPlayerId, v44_, v63_, v49_, v50_)
			ambientSoundsSampleSetMinMaxVolume(self.soundPlayerId, v44_, v63_, v51_, v52_)
			ambientSoundsSampleSetMinMaxLoops(self.soundPlayerId, v44_, v63_, v54_, v55_)
			ambientSoundsSampleSetMinMaxPitch(self.soundPlayerId, v44_, v63_, v56_, v57_)
			ambientSoundsSampleSetMinMaxDelay(self.soundPlayerId, v44_, v63_, v58_, v59_)
			ambientSoundsSampleSetMinMaxLength(self.soundPlayerId, v44_, v63_, v60_, v61_)
		end
		local v64_ = self.samples
		table.insert(v64_, {
			["filename"] = v41_,
			["audioGroupId"] = v40_,
			["requiredFlags"] = v42_,
			["preventFlags"] = v43_,
			["minTimeOfDay"] = v36_,
			["maxTimeOfDay"] = v37_,
			["minDayOfYear"] = v38_,
			["maxDayOfYear"] = v39_
		})
	end
	local v65_ = v13_:getValue("sound.ambient3d#filename")
	if v65_ ~= nil then
		local v66_ = Utils.getFilename(v65_, self.baseDirectory)
		self.loadRequestId = g_i3DManager:loadI3DFileAsync(v66_, true, false, AmbientSoundSystem.sound3DFileLoaded, self, nil)
	end
	v13_:delete()
	g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.onWeatherChanged, self)
	g_messageCenter:subscribe(MessageType.OWN_PLAYER_ENTERED, self.onPlayerEntered, self)
	g_messageCenter:subscribe(MessageType.OWN_PLAYER_LEFT, self.onPlayerLeft, self)
	return true
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

-- Local values: numChildren, spline, transformNode, splineLength, eps, modifiers, modifiersNode, i, modifierNode, startNode, endNode, sx, sy, sz, _, _, _, startTime, ex, ey, ez, _, _, _, endTime, rangeScale, fadeDistance, fadeDistanceTime, startTimeFadeEnd, endTimeFadeStart, sounds, i, soundNode, x, y, z, innerRange, outerRange, movingSoundEntry
function AmbientSoundSystem:addMovingSound(node)
	local v71_ = getNumOfChildren(node)
	if v71_ < 2 or v71_ > 3 then
		Logging.devWarning("AmbientSoundSystem:addMovingSound(): Invalid number of children given for node \'%s\'", getName(node))
	else
		local v72_ = getChildAt(node, 0)
		local v73_ = getChildAt(node, 1)
		if getHasClassId(getGeometry(v72_), ClassIds.SPLINE) then
			setVisibility(v72_, false)
			local v74_ = getSplineLength(v72_)
			local v75_ = 0.01 / v74_
			local v76_ = {}
			if v71_ == 3 then
				local v77_ = getChildAt(node, 2)
				for v78_ = 0, getNumOfChildren(v77_) - 1 do
					local v79_ = getChildAt(v77_, v78_)
					local v80_ = getChildAt(v79_, 0)
					local v81_ = getChildAt(v79_, 1)
					local v82_, v83_, v84_ = getWorldTranslation(v80_)
					local _, _, _, v85_ = getClosestSplinePosition(v72_, v82_, v83_, v84_, v75_)
					local v86_, v87_, v88_ = getWorldTranslation(v81_)
					local _, _, _, v89_ = getClosestSplinePosition(v72_, v86_, v87_, v88_, v75_)
					if v89_ >= v85_ then
						local v90_ = v85_
						v85_ = v89_
						v89_ = v90_
					end
					local v91_ = getUserAttribute
					local v92_ = tonumber(v91_(v79_, "rangeScale"))
					local v93_ = getUserAttribute
					local v94_ = tonumber(v93_(v79_, "fadeDistance"))
					local v95_ = v94_ / v74_
					local v96_ = {
						["startTime"] = v89_,
						["startTimeFadeEnd"] = v89_ + v95_,
						["endTime"] = v85_,
						["endTimeFadeStart"] = v85_ - v95_,
						["rangeScale"] = v92_,
						["fadeDistance"] = v94_
					}
					table.insert(v76_, v96_)
				end
			end
			table.sort(v76_, function(p97_, p98_)
				return p97_.startTime < p98_.startTime
			end)
			local v99_ = {}
			for v100_ = 0, getNumOfChildren(v73_) - 1 do
				local v101_ = getChildAt(v73_, v100_)
				if getHasClassId(v101_, ClassIds.AUDIO_SOURCE) then
					local v102_, v103_, v104_ = getTranslation(v101_)
					if v102_ == 0 and (v103_ == 0 and v104_ == 0) then
						local v105_ = {
							["node"] = v101_,
							["innerRange"] = getAudioSourceInnerRange(v101_),
							["outerRange"] = getAudioSourceRange(v101_)
						}
						table.insert(v99_, v105_)
					else
						Logging.warning("AmbientsoundSystem:addMovingSound(): Child \'%s\' of transform \'%s\' is offset (translation not 0 0 0)", getName(v101_), I3DUtil.getNodePath(v73_))
					end
				else
					Logging.warning("AmbientsoundSystem:addMovingSound(): Child \'%s\' of transform \'%s\' is not an audio source", getName(v101_), I3DUtil.getNodePath(v73_))
				end
			end
			local v106_ = {
				["spline"] = v72_,
				["node"] = v73_,
				["eps"] = v75_,
				["sounds"] = v99_,
				["modifiers"] = v76_
			}
			local v107_ = self.movingSounds
			table.insert(v107_, v106_)
			return v106_
		end
		Logging.error("AmbientsoundSystem:addMovingSound(): First child \'%s\' of given node \'%s\' is not a spline!", getName(v72_), getName(node))
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

-- Local values: environment, minuteOfDay, dayOfYear, mask, x, y, z, _, movingSound, sx, sy, sz, t, rangeScale, _, modifier, alpha, _, sound, _, modifier, debugX, debugY, debugZ
function AmbientSoundSystem:update(dt)
	if self.soundPlayerId ~= nil then
		local v113_ = g_currentMission.environment
		if v113_ ~= nil then
			local v114_ = v113_:getMinuteOfDay()
			local v115_ = v113_:getDayOfYear()
			local v116_ = math.clamp(v115_, 0, 365)
			ambientSoundsSetTimeAndDay(self.soundPlayerId, v114_, v116_)
			self:updateMask()
			local v117_ = self.conditionFlags:getMask()
			ambientSoundsUpdate(self.soundPlayerId, dt, v117_)
		end
	end
	local v118_, v119_, v120_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	for _, v121_ in ipairs(self.movingSounds) do
		local v122_, v123_, v124_, v125_ = getClosestSplinePosition(v121_.spline, v118_, v119_, v120_, v121_.eps)
		setWorldTranslation(v121_.node, v122_, v123_, v124_)
		local v126_ = 1
		for _, v127_ in ipairs(v121_.modifiers) do
			if v127_.startTime <= v125_ and v125_ <= v127_.endTime then
				local v128_ = v125_ > v127_.startTimeFadeEnd and 1 or 1 - (v127_.startTimeFadeEnd - v125_) / (v127_.startTimeFadeEnd - v127_.startTime)
				if v127_.endTimeFadeStart < v125_ then
					v128_ = (v127_.endTime - v125_) / (v127_.endTime - v127_.endTimeFadeStart)
				end
				v126_ = MathUtil.lerp(1, v127_.rangeScale, v128_)
				break
			end
		end
		if v121_.lastScale ~= v126_ then
			for _, v129_ in ipairs(v121_.sounds) do
				setAudioSourceInnerRange(v129_.node, v129_.innerRange * v126_)
				setAudioSourceRange(v129_.node, v129_.outerRange * v126_)
			end
			v121_.lastScale = v126_
		end
		if self.isDebugViewActive then
			DebugPoint.renderAtPosition(v122_, v123_, v124_, nil, false, string.format("%s (RangeScale=%.3f)", getName(v121_.node), v126_))
			for _, v130_ in ipairs(v121_.modifiers) do
				local v131_, v132_, v133_ = getSplinePosition(v121_.spline, v130_.startTime)
				DebugFlag.renderAtPosition(v131_, v132_, v133_, 1, 0, DebugUtil.tableToColor(v130_), "startTime")
				local v134_, v135_, v136_ = getSplinePosition(v121_.spline, v130_.startTimeFadeEnd)
				DebugFlag.renderAtPosition(v134_, v135_, v136_, 1, 0, DebugUtil.tableToColor(v130_), "startTimeFadeEnd")
				local v137_, v138_, v139_ = getSplinePosition(v121_.spline, v130_.endTime)
				DebugFlag.renderAtPosition(v137_, v138_, v139_, 1, 0, DebugUtil.tableToColor(v130_), "endTime")
				local v140_, v141_, v142_ = getSplinePosition(v121_.spline, v130_.endTimeFadeStart)
				DebugFlag.renderAtPosition(v140_, v141_, v142_, 1, 0, DebugUtil.tableToColor(v130_), "endTimeFadeStart")
			end
		end
	end
end

-- Local values: conditionFlags, mission, weights, isOpenField, isInForest, environment, weather, isRaining, isSnowing, isHailing, _, _, windVelocity, season
function AmbientSoundSystem:updateMask()
	local v144_ = self.conditionFlags
	local v145_ = g_currentMission
	local v146_ = v145_.environmentAreaSystem:getAreaWeights()
	local v147_ = v146_.areaTypeWeights[AreaType.OPEN_FIELD] > 0.5
	local v148_
	if v147_ then
		v148_ = v146_.isInForestWeight > 0.5
	else
		v148_ = v147_
	end
	if v148_ then
		v147_ = false
	end
	v144_:setModifierValue("inForest", v148_)
	v144_:setModifierValue("nearWater", v146_.isNearWaterWeight > 0.5)
	v144_:setModifierValue("nearWall", v146_.isNearWallWeight > 0.5)
	v144_:setModifierValue("underRoof", v146_.isUnderRoofWeight > 0.5)
	v144_:setModifierValue("areaOpenField", v147_)
	v144_:setModifierValue("areaCity", v146_.areaTypeWeights[AreaType.CITY] > 0.5)
	v144_:setModifierValue("areaVillage", v146_.areaTypeWeights[AreaType.VILLAGE] > 0.5)
	v144_:setModifierValue("areaHarbor", v146_.areaTypeWeights[AreaType.HARBOR] > 0.5)
	v144_:setModifierValue("areaIndustrial", v146_.areaTypeWeights[AreaType.INDUSTRIAL] > 0.5)
	v144_:setModifierValue("areaOpenWater", v146_.areaTypeWeights[AreaType.OPEN_WATER] > 0.5)
	local v149_ = v145_.environment
	local v150_ = v149_.weather
	local v151_ = v150_:getRainFallScale() > 0
	local v152_ = v150_:getSnowFallScale() > 0
	local v153_ = v150_:getIsHailing()
	v144_:setModifierValue("rain", v151_)
	v144_:setModifierValue("snow", v152_)
	v144_:setModifierValue("hail", v153_)
	local _, _, v154_ = v150_.windUpdater:getCurrentValues()
	v144_:setModifierValue("windSpeedLow", v154_ < 6)
	local v155_ = "windSpeedMedium"
	local v156_
	if v154_ >= 6 then
		v156_ = v154_ < 20
	else
		v156_ = false
	end
	v144_:setModifierValue(v155_, v156_)
	v144_:setModifierValue("windSpeedHigh", v154_ >= 20)
	local v157_ = SeasonPeriod.getSeason(v149_.currentVisualPeriod)
	v144_:setModifierValue("spring", v157_ == Season.SPRING)
	v144_:setModifierValue("summer", v157_ == Season.SUMMER)
	v144_:setModifierValue("autumn", v157_ == Season.AUTUMN)
	v144_:setModifierValue("winter", v157_ == Season.WINTER)
end

function AmbientSoundSystem:setIsEnabled(isEnabled)
	if self.soundPlayerId ~= nil then
		ambientSoundsSetEnabled(self.soundPlayerId, isEnabled)
	end
end

-- Local values: conditionFlags
function AmbientSoundSystem:setIsIndoor(isIndoor)
	self.conditionFlags:setModifierValue("isIndoor", isIndoor)
	if self.soundPlayerId ~= nil then
		ambientSoundsSetIsIndoor(self.soundPlayerId, isIndoor)
	end
end

-- Local values: typeIndex, conditionFlags
function AmbientSoundSystem:onWeatherChanged(weatherObject)
	local v164_ = weatherObject.weatherType
	local v165_ = self.conditionFlags
	v165_:setModifierValue("sun", v164_ == WeatherType.SUN)
	v165_:setModifierValue("cloudy", v164_ == WeatherType.CLOUDY)
end

-- Local values: conditionFlags
function AmbientSoundSystem:onPlayerEntered()
	local v167_ = self.conditionFlags
	v167_:setModifierValue("outVehicle", true)
	v167_:setModifierValue("inVehicle", false)
end

-- Local values: conditionFlags
function AmbientSoundSystem:onPlayerLeft()
	local v169_ = self.conditionFlags
	v169_:setModifierValue("outVehicle", false)
	v169_:setModifierValue("inVehicle", true)
end

-- Local values: posY, textSize, textOffset, _, sample, match
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
		local v171_ = getCorrectTextSize(0.012)
		local v172_ = getCorrectTextSize(0.001)
		local v173_ = 0.7
		for _, v174_ in ipairs(self.samples) do
			if self:isSamplePossible(v174_) then
				renderText(0.1, v173_, v171_, AudioGroup.getAudioGroupNameByIndex(v174_.audioGroupId))
				renderText(0.2, v173_, v171_, v174_.filename)
				v173_ = v173_ - v171_ - v172_
			end
		end
		local v175_ = self.conditionFlags:drawDebug(0.7, 0.72) - v171_ - v172_
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.7, v175_, v171_, "time of day: ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v176_ = renderText
		local v177_ = g_currentMission.environment
		v176_(0.7, v175_, v171_, (tostring(v177_:getMinuteOfDay())))
		local v178_ = v175_ - v171_ - v172_
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.7, v178_, v171_, "day of year: ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v179_ = renderText
		local v180_ = g_currentMission.environment
		v179_(0.7, v178_, v171_, (tostring(v180_:getDayOfYear())))
	end
end

function AmbientSoundSystem:consoleCommandReload()
	self:unloadAmbientSounds()
	self:loadFromConfigFile()
end

-- Local values: mission, _, movingSound
function AmbientSoundSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive
	local v183_ = g_currentMission
	if self.isDebugViewActive then
		v183_:addDrawable(self)
	else
		v183_:removeDrawable(self)
	end
	for _, v184_ in ipairs(self.movingSounds) do
		setVisibility(v184_.spline, self.isDebugViewActive)
	end
end

-- Local values: mask, match, environment, minuteOfDay, minTimeOfDay, maxTimeOfDay, dayOfYear, minDayOfYear, maxDayOfYear
function AmbientSoundSystem:isSamplePossible(sample)
	local v187_ = self.conditionFlags:getMask()
	local v188_ = sample.preventFlags
	local v189_
	if bit32.band(v187_, v188_) == 0 then
		local v190_ = sample.requiredFlags
		v189_ = bit32.band(v187_, v190_) == sample.requiredFlags
	else
		v189_ = false
	end
	if not v189_ then
		return false
	end
	local v191_ = g_currentMission.environment
	local v192_ = v191_:getMinuteOfDay()
	local v193_ = sample.minTimeOfDay
	local v194_ = sample.maxTimeOfDay
	if MathUtil.getIsOutOfBounds(v192_, v193_, v194_) then
		return false
	end
	local v195_ = v191_:getDayOfYear()
	local v196_ = sample.minDayOfYear
	local v197_ = sample.maxDayOfYear
	return not MathUtil.getIsOutOfBounds(v195_, v196_, v197_)
end
