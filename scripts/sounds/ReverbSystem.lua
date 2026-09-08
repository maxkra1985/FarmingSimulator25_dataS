-- Local values: ReverbSystem_mt
ReverbSystem = {}
local ReverbSystem_mt = Class(ReverbSystem)

-- Local values: name, id
function ReverbSystem.getName(index)
	for v3_, v4_ in pairs(Reverb) do
		if v4_ == index then
			return v3_
		end
	end
	return nil
end

-- Upvalues: ReverbSystem_mt
-- Local values: self
function ReverbSystem.new(mission, customMt)
	-- upvalues: (copy) ReverbSystem_mt
	local v7_ = customMt or ReverbSystem_mt
	local v8_ = setmetatable({}, v7_)
	v8_.mission = mission
	v8_.isDebugViewActive = false
	v8_.AREA_TYPE_TO_REVERB_TYPE = {}
	v8_.AREA_TYPE_TO_REVERB_TYPE[AreaType.OPEN_FIELD] = Reverb.GS_OPEN_FIELD
	v8_.AREA_TYPE_TO_REVERB_TYPE[AreaType.OPEN_WATER] = Reverb.GS_OPEN_FIELD
	v8_.AREA_TYPE_TO_REVERB_TYPE[AreaType.CITY] = Reverb.GS_CITY
	v8_.AREA_TYPE_TO_REVERB_TYPE[AreaType.VILLAGE] = Reverb.GS_CITY
	v8_.AREA_TYPE_TO_REVERB_TYPE[AreaType.HARBOR] = Reverb.GS_CITY
	v8_.AREA_TYPE_TO_REVERB_TYPE[AreaType.INDUSTRIAL] = Reverb.GS_CITY
	v8_.blendFactor = 0
	v8_.reverbType1 = Reverb.GS_OPEN_FIELD
	v8_.reverbType2 = Reverb.GS_OPEN_FIELD
	v8_.targetReverbTypes = {}
	v8_.targetReverbTypes[1] = {
		["type"] = Reverb.GS_OPEN_FIELD,
		["weight"] = 1
	}
	v8_.targetReverbTypes[2] = {
		["type"] = Reverb.GS_OPEN_FIELD,
		["weight"] = 0
	}
	return v8_
end

-- Local values: xmlFilename, customXmlFilename
function ReverbSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	local v12_ = "data/sounds/reverbSettings.xml"
	local v13_ = getXMLString(mapXmlFile, "map.sounds#reverbFilename")
	if v13_ ~= nil then
		local v14_ = Utils.getFilename(v13_, baseDirectory)
		if fileExists(v14_) then
			v12_ = v14_
		else
			Logging.warning("ReverbSystem custom config file not found!")
		end
	end
	self.xmlFilename = v12_
	addConsoleCommand("gsReverbSystemToggleDebugView", "Toggles the reverb debug view", "consoleCommandToggleDebugView", self)
	addConsoleCommand("gsReverbSystemSettingsReload", "Reloads the reverb settings", "consoleCommandReloadSettings", self)
	return self:loadSettings()
end

-- Local values: xmlFile, _, settingKey, id, presetId, lateReverbGain, lateReverbDelay, gain, gainHF, gainLF, decayTime, decayHFRatio, reflectionsGain, reflectionsDelay, referenceHF, referenceLF
function ReverbSystem:loadSettings()
	local v16_ = XMLFile.load("ReverbSettings", self.xmlFilename, nil)
	if v16_ == nil then
		Logging.xmlWarning(v16_, "ReverbSystem could not load configuration xml file!")
		return false
	end
	for _, v17_ in v16_:iterator("reverbSettings.reverbSetting") do
		local v18_ = v16_:getString(v17_ .. "#id")
		if v18_ == nil then
			Logging.warning("ReverbSystem: missing id for reverb setting \'%s\'!", v17_)
		else
			local v19_ = string.upper(v18_)
			if Reverb[v19_] == nil then
				Logging.warning("ReverbSystem: Invalid id \'%s\' for reverb setting \'%s\'!", v19_, v17_)
			else
				local v20_ = Reverb[v19_]
				local v21_, v22_ = getLateReverbGainPreset(v20_)
				local v23_ = v16_:getFloat(v17_ .. ".lateReverb#gain", v21_)
				local v24_ = v16_:getFloat(v17_ .. ".lateReverb#delay", v22_)
				local v25_, v26_, v27_ = getReverbGainPreset(v20_)
				local v28_ = v16_:getFloat(v17_ .. ".gain#gain", v25_)
				local v29_ = v16_:getFloat(v17_ .. ".gain#gainHF", v26_)
				local v30_ = v16_:getFloat(v17_ .. ".gain#gainLF", v27_)
				local v31_, v32_ = getReverbDecayPreset(v20_)
				local v33_ = v16_:getFloat(v17_ .. ".decay#time", v31_)
				local v34_ = v16_:getFloat(v17_ .. ".decay#ratioHF", v32_)
				local v35_, v36_ = getReverbReflectionPreset(v20_)
				local v37_ = v16_:getFloat(v17_ .. ".reflections#gain", v35_)
				local v38_ = v16_:getFloat(v17_ .. ".reflections#delay", v36_)
				local v39_, v40_ = getReverbReferenceFrequenciesPreset(v20_)
				local v41_ = v16_:getFloat(v17_ .. ".reference#referenceHF", v39_)
				local v42_ = v16_:getFloat(v17_ .. ".reference#referenceLF", v40_)
				if v41_ <= 0 then
					Logging.xmlError(v16_, "Reverb setting \'referenceHF\' at \'%s\' needs to be bigger than 0", v17_)
				elseif v42_ <= 0 then
					Logging.xmlError(v16_, "Reverb setting \'referenceLF\' at \'%s\' needs to be bigger than 0", v17_)
				else
					setReverbPreset(v20_, v28_, v29_, v30_, v33_, v34_, v37_, v38_, v23_, v24_, v41_, v42_)
				end
			end
		end
	end
	v16_:delete()
	return true
end

function ReverbSystem:delete()
	g_debugManager:removeDrawable(self)
	removeConsoleCommand("gsReverbSystemToggleDebugView")
	removeConsoleCommand("gsReverbSystemSettingsReload")
	self.mission = nil
end

-- Local values: areaWeights, reverbType1, reverbType2, reverbType1Weight, reverbType2Weight, areaTypeIndex, weight, reverbTypeIndex, sum, fadeDelta, areEqual, isFirstTypeCorrect, isSecondTypeCorrect, newReverbType1, newReverbType2, targetBlendFactor
function ReverbSystem:update(dt)
	if self.mission ~= nil then
		local v46_ = self.mission.environmentAreaSystem:getAreaWeights()
		local v47_ = nil
		local v48_ = nil
		local v49_ = 0
		local v50_ = 0
		for v51_, v54_ in pairs(v46_.areaTypeWeights) do
			local v53_ = self.AREA_TYPE_TO_REVERB_TYPE[v51_]
			if v53_ ~= nil then
				local v54_
				if v47_ == nil then
					v50_ = v54_
					v54_ = v49_
					v47_ = v53_
					v53_ = v48_
				elseif v48_ ~= nil and v49_ >= v54_ then
					v54_ = v49_
					v53_ = v48_
				end
				v47_, v48_, v50_, v49_ = self:sortTypes(v47_, v53_, v50_, v54_)
			end
		end
		if v48_ == nil or v49_ < v46_.isInForestWeight then
			v47_, v48_, v50_, v49_ = self:sortTypes(v47_, Reverb.GS_FOREST, v50_, v46_.isInForestWeight)
		end
		if v48_ == nil or v49_ < v46_.isNearWallWeight then
			v47_, v48_, v50_, v49_ = self:sortTypes(v47_, Reverb.GS_CITY, v50_, v46_.isNearWallWeight)
		end
		if v48_ == nil or v46_.isUnderRoofWeight > 0.4 then
			v47_, v48_, v50_, v49_ = self:sortTypes(v47_, Reverb.GS_INDOOR_HALL, v50_, 1)
		end
		local v55_ = v47_ or Reverb.GS_OPEN_FIELD
		local v56_ = v48_ or Reverb.GS_OPEN_FIELD
		local v57_ = v50_ + v49_
		local v58_ = v57_ == 0 and 1 or v57_
		local v59_ = dt / 400
		self.targetReverbTypes[1].type = v55_
		self.targetReverbTypes[1].weight = v50_ / v58_
		self.targetReverbTypes[1].name = ReverbSystem.getName(v55_)
		self.targetReverbTypes[2].type = v56_
		self.targetReverbTypes[2].name = ReverbSystem.getName(v56_)
		self.targetReverbTypes[2].weight = v49_ / v58_
		local v60_ = self.reverbType1 == self.reverbType2
		local v61_ = self.reverbType1 == self.targetReverbTypes[1].type and true or self.reverbType1 == self.targetReverbTypes[2].type
		local v62_ = not v60_ and self.reverbType2 == self.targetReverbTypes[1].type and true or self.reverbType2 == self.targetReverbTypes[2].type
		local v63_ = self.reverbType1
		local v64_ = self.reverbType2
		if v61_ and v62_ then
			local v65_ = 1 - self.targetReverbTypes[1].weight
			if self.reverbType1 ~= self.targetReverbTypes[1].type then
				v65_ = self.targetReverbTypes[1].weight
			end
			if v65_ < self.blendFactor then
				local v66_ = self.blendFactor - v59_
				self.blendFactor = math.max(v66_, v65_)
			else
				local v67_ = self.blendFactor + v59_
				self.blendFactor = math.min(v67_, v65_)
			end
		elseif v61_ then
			if self.blendFactor == 0 then
				if self.reverbType1 == self.targetReverbTypes[1].type then
					v64_ = self.targetReverbTypes[2].type
				else
					v64_ = self.targetReverbTypes[1].type
				end
			end
			local v68_ = self.blendFactor - v59_
			self.blendFactor = math.max(v68_, 0)
		else
			if self.blendFactor == 1 then
				if self.reverbType2 == self.targetReverbTypes[1].type then
					v63_ = self.targetReverbTypes[2].type
				else
					v63_ = self.targetReverbTypes[1].type
				end
			end
			local v69_ = self.blendFactor + v59_
			self.blendFactor = math.min(v69_, 1)
		end
		self.reverbType1 = v63_
		self.reverbType2 = v64_
		setReverbEffect(SoundManager.DEFAULT_REVERB_EFFECT, self.reverbType1, self.reverbType2, self.blendFactor)
	end
end

function ReverbSystem:sortTypes(reverbType1, reverbType2, reverbType1Weight, reverbType2Weight)
	if reverbType1 == nil or reverbType2 == nil then
		local v74_ = reverbType1Weight
		reverbType1Weight = reverbType2Weight
		reverbType2Weight = v74_
		v74_ = reverbType1
		reverbType1 = reverbType2
		reverbType2 = v74_
	elseif reverbType1Weight >= reverbType2Weight then
		local v75_ = reverbType1Weight
		reverbType1Weight = reverbType2Weight
		reverbType2Weight = v75_
		v75_ = reverbType1
		reverbType1 = reverbType2
		reverbType2 = v75_
	end
	return reverbType2, reverbType1, reverbType2Weight, reverbType1Weight
end

-- Local values: type1, type2
function ReverbSystem:drawDebug()
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
	local v77_ = self.reverbType1
	local v78_ = self.reverbType2
	renderText(0.7, 0.5, 0.012, string.format("Current: %s %.3f -> %s %.3f", ReverbSystem.getName(v77_), 1 - self.blendFactor, ReverbSystem.getName(v78_), self.blendFactor))
	renderText(0.7, 0.45, 0.012, string.format("Target: %s %.3f -> %s %.3f", self.targetReverbTypes[1].name, self.targetReverbTypes[1].weight, self.targetReverbTypes[2].name, self.targetReverbTypes[2].weight))
end

function ReverbSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive
	if self.isDebugViewActive then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
end

function ReverbSystem:consoleCommandReloadSettings()
	self:loadSettings()
	return "Reloaded settings"
end
