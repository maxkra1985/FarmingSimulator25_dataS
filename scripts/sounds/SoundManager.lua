-- Local values: SoundManager_mt
SoundModifierType = nil
SoundManager = {}
SoundManager.DEFAULT_REVERB_EFFECT = 0
SoundManager.MAX_SAMPLES_PER_FRAME = 5
SoundManager.DEFAULT_SOUND_TEMPLATES = "data/sounds/soundTemplates.xml"
SoundManager.SAMPLE_MODIFIER_ATTRIBUTES = {
	"volume",
	"pitch",
	"lowpassGain",
	"loopSynthesisRpm",
	"loopSynthesisLoad"
}
SoundManager.SAMPLE_RANDOMIZATIONS = { "randomizationsIn", "randomizationsOut" }
SoundManager.GLOBAL_DEBUG_ENABLED = false
local SoundManager_mt = Class(SoundManager, AbstractManager)

-- Upvalues: SoundManager_mt
-- Local values: self
function SoundManager.new(customMt)
	-- upvalues: (copy) SoundManager_mt
	local v3_ = AbstractManager.new(customMt or SoundManager_mt)
	addConsoleCommand("gsSoundManagerDebug", "Toggle SoundManager global debug mode", "consoleCommandToggleDebug", v3_)
	return v3_
end

function SoundManager:initDataStructures()
	self.samples = {}
	self.orderedSamples = {}
	self.activeSamples = {}
	self.activeSamplesSet = {}
	self.debugSamplesFlagged = {}
	self.debugSamples = {}
	self.debugSamplesLinkNodes = {}
	self.currentSampleIndex = 1
	self.oldRandomizationIndex = 1
	self.isIndoor = false
	self.soundTemplates = {}
	self.soundTemplateXMLFile = nil
	self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)
	self.modifierTypeNameToIndex = {}
	self.modifierTypeIndexToDesc = {}
	SoundModifierType = self.modifierTypeNameToIndex
	setReverbEffect(0, Reverb.GS_OPEN_FIELD, Reverb.GS_OPEN_FIELD, 1)
	self.indoorStateChangedListeners = {}
end

function SoundManager:delete()
	if self.soundTemplateXMLFile ~= nil then
		delete(self.soundTemplateXMLFile)
		self.soundTemplateXMLFile = nil
	end
end

-- Local values: desc
function SoundManager:registerModifierType(typeName, func, minFunc, maxFunc)
	local v11_ = string.upper(typeName)
	if SoundModifierType[v11_] == nil then
		if type(func) ~= "function" then
			Logging.error("SoundManager.registerModifierType: parameter \'func\' is of type \'%s\'. Possibly the registerModifierType is called before the definition of the function?", (type(func)))
			printCallstack()
			return
		end
		local v12_ = {
			["name"] = v11_,
			["index"] = #self.modifierTypeIndexToDesc + 1,
			["func"] = func,
			["minFunc"] = minFunc,
			["maxFunc"] = maxFunc
		}
		SoundModifierType[v11_] = v12_.index
		local v13_ = self.modifierTypeIndexToDesc
		table.insert(v13_, v12_)
	end
	return SoundModifierType[v11_]
end

-- Local values: xmlFile, i, key, name
function SoundManager:loadSoundTemplates(xmlFilename)
	local v16_ = loadXMLFile("soundTemplates", xmlFilename)
	if v16_ == 0 then
		return false
	end
	local v17_ = 0
	while true do
		local v18_ = string.format("soundTemplates.template(%d)", v17_)
		if not hasXMLProperty(v16_, v18_) then
			break
		end
		local v19_ = getXMLString(v16_, v18_ .. "#name")
		if v19_ ~= nil then
			if self.soundTemplates[v19_] == nil then
				self.soundTemplates[v19_] = v18_
			else
				Logging.xmlWarning(v16_, "Sound template \'%s\' already exists!", v19_)
			end
		end
		v17_ = v17_ + 1
	end
	self.soundTemplateXMLFile = v16_
	return true
end

-- Local values: k, _
function SoundManager:reloadSoundTemplates()
	for v21_, _ in pairs(self.soundTemplates) do
		self.soundTemplates[v21_] = nil
	end
	if entityExists(self.soundTemplateXMLFile) then
		delete(self.soundTemplateXMLFile)
		self.soundTemplateXMLFile = nil
	end
	self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)
end

-- Local values: newSample, _, randomSample, newRandomSample
function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
	local v26_ = table.clone(sample)
	v26_.modifiers = table.clone(sample.modifiers)
	if not sample.is2D then
		v26_.soundNode = createAudioSource(v26_.sampleName, v26_.filename, v26_.outerRadius, v26_.innerRadius, v26_.current.volume, v26_.loops)
		v26_.soundSample = getAudioSourceSample(v26_.soundNode)
		setAudioSourceAutoPlay(v26_.soundNode, false)
		link(linkNode, v26_.soundNode)
		v26_.linkNode = linkNode
		if v26_.linkNodeOffset == nil then
			setTranslation(v26_.soundNode, 0, 0, 0)
		else
			setTranslation(v26_.soundNode, v26_.linkNodeOffset[1], v26_.linkNodeOffset[2], v26_.linkNodeOffset[3])
		end
	end
	setSampleGroup(v26_.soundSample, sample.audioGroup)
	v26_.audioGroup = sample.audioGroup
	if sample.supportsReverb then
		addSampleEffect(v26_.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
	else
		removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
	end
	if modifierTargetObject ~= nil then
		v26_.modifierTargetObject = modifierTargetObject
	end
	if sample.sourceRandomizations ~= nil then
		v26_.sourceRandomizations = {}
		for _, v27_ in ipairs(sample.sourceRandomizations) do
			local v28_ = self:getRandomSample(sample, v27_.filename)
			local v29_ = v26_.sourceRandomizations
			table.insert(v29_, v28_)
		end
	end
	self.samples[v26_] = v26_
	local v30_ = self.orderedSamples
	table.insert(v30_, v26_)
	return v26_
end

-- Local values: newSample, _, randomSample, newRandomSample
function SoundManager:cloneSample2D(sample, linkNode, modifierTargetObject)
	local v34_ = table.clone(sample)
	v34_.modifiers = table.clone(sample.modifiers)
	v34_.audioGroup = sample.audioGroup
	v34_.linkNode = nil
	v34_.soundNode = nil
	v34_.is2D = true
	v34_.soundSample = createSample(v34_.sampleName)
	v34_.orgSoundSample = v34_.soundSample
	loadSample(v34_.soundSample, v34_.filename, false)
	v34_.duration = getSampleDuration(v34_.soundSample)
	setSampleGroup(v34_.soundSample, sample.audioGroup)
	v34_.audioGroup = sample.audioGroup
	if modifierTargetObject ~= nil then
		v34_.modifierTargetObject = modifierTargetObject
	end
	if sample.sourceRandomizations ~= nil then
		v34_.sourceRandomizations = {}
		for _, v35_ in ipairs(sample.sourceRandomizations) do
			local v36_ = {
				["filename"] = v35_.filename,
				["isEmpty"] = v35_.isEmpty,
				["is2D"] = true
			}
			if not v35_.isEmpty then
				v36_.soundSample = createSample(v34_.sampleName)
				loadSample(v36_.soundSample, v36_.filename, false)
			end
			local v37_ = v34_.sourceRandomizations
			table.insert(v37_, v36_)
		end
	end
	self.samples[v34_] = v34_
	local v38_ = self.orderedSamples
	table.insert(v38_, v34_)
	return v34_
end

-- Local values: isValid, usedExternal, actualXMLFile, sampleKey, linkNode, xmlFileObject
function SoundManager:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, is2D, components, i3dMappings, externalSoundsFile)
	local v47_ = false
	local v48_ = false
	local v49_ = nil
	local v50_, v51_
	if sampleName == nil then
		v50_ = xmlFile
		v51_ = ""
	else
		if not AudioGroup.getIsValidAudioGroup(audioGroup) then
			printWarning("Warning: Invalid audioGroup index \'" .. tostring(audioGroup) .. "\'.")
		end
		v51_ = baseKey .. "." .. sampleName
		if externalSoundsFile == nil or hasXMLProperty(xmlFile, v51_) then
			v50_ = xmlFile
		else
			v51_ = Vehicle.xmlSchemaSounds:replaceRootName(v51_)
			v50_ = externalSoundsFile.handle
			v48_ = true
		end
		local v52_ = g_xmlManager:getFileByHandle(xmlFile)
		if v52_ ~= nil then
			XMLUtil.checkDeprecatedXMLElements(v52_, baseKey .. "#externalSoundFile", "vehicle.base.sounds#filename")
		end
		if v50_ == nil then
			Logging.warning("Unable to load sample \'%s\' from internal or given external sound file \'%s\'!", sampleName, externalSoundsFile)
		elseif hasXMLProperty(v50_, v51_) then
			v47_ = true
			if not is2D then
				v49_ = I3DUtil.indexToObject(components, getXMLString(v50_, v51_ .. "#linkNode"), i3dMappings)
				if v49_ == nil then
					if type(components) == "number" then
						return v47_, v48_, v50_, v51_, components
					end
					if type(components) == "table" then
						return v47_, v48_, v50_, v51_, components[1].node
					end
					local v53_ = printWarning
					local v54_ = getXMLString
					local v55_ = v51_ .. "#linkNode"
					v53_("Warning: Could not find linkNode (" .. tostring(v54_(v50_, v55_)) .. ") for sample \'" .. tostring(sampleName) .. "\'. Ignoring it!")
					return false, v48_, v50_, v51_, v49_
				end
			end
		end
	end
	return v47_, v48_, v50_, v51_, v49_
end

-- Local values: sample, isValid, usedExternal, definitionXmlFile, sampleKey, template
function SoundManager:loadSample2DFromXML(xmlFile, baseKey, sampleName, baseDir, loops, audioGroup, requiresFile)
	if type(xmlFile) == "table" then
		xmlFile = xmlFile.handle
	end
	local v64_, v65_, v66_, v67_ = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, true)
	local v68_
	if v64_ then
		v68_ = {
			["is2D"] = true,
			["sampleName"] = sampleName
		}
		local v69_ = getXMLString(v66_, v67_ .. "#template")
		if v69_ ~= nil then
			v68_ = self:loadSampleAttributesFromTemplate(v68_, v69_, baseDir, loops, v66_, v67_)
			if v68_ == nil then
				return nil
			end
		end
		if not self:loadSampleAttributesFromXML(v68_, v66_, v67_, baseDir, loops, requiresFile) then
			return nil
		end
		v68_.filename = Utils.getFilename(v68_.filename, baseDir)
		v68_.linkNode = nil
		v68_.current = v68_.outdoorAttributes
		v68_.audioGroup = audioGroup
		v68_.supportsReverb = Utils.getNoNil(getXMLBool(xmlFile, v67_ .. "#supportsReverb"), true)
		self:createAudio2d(v68_, v68_.filename)
		v68_.offsets = {
			["volume"] = 0,
			["pitch"] = 0,
			["lowpassGain"] = 0
		}
		self.samples[v68_] = v68_
		local v70_ = self.orderedSamples
		table.insert(v70_, v68_)
	else
		v68_ = nil
	end
	if v65_ then
		delete(v66_)
	end
	return v68_
end

-- Local values: sample, externalSoundsFile, volumeFactor, isValid, _, definitionXmlFile, sampleKey, linkNode, template
function SoundManager:loadSampleFromXML(xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject, requiresFile)
	local v82_ = nil
	if type(xmlFile) == "table" then
		xmlFile = xmlFile.handle
	end
	local v83_, v84_
	if modifierTargetObject == nil then
		v83_ = nil
		v84_ = nil
	else
		v84_ = modifierTargetObject.externalSoundsFile
		v83_ = modifierTargetObject.soundVolumeFactor
	end
	local v85_, _, v86_, v87_, v88_ = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, false, components, i3dMappings, v84_)
	if v85_ then
		v82_ = {
			["is2D"] = false,
			["sampleName"] = sampleName
		}
		local v89_ = getXMLString(v86_, v87_ .. "#template")
		if v89_ ~= nil then
			v82_ = self:loadSampleAttributesFromTemplate(v82_, v89_, baseDir, loops, v86_, v87_)
			if v82_ == nil then
				return nil
			end
		end
		if not self:loadSampleAttributesFromXML(v82_, v86_, v87_, baseDir, loops, requiresFile) then
			return nil
		end
		v82_.filename = Utils.getFilename(v82_.filename, baseDir)
		v82_.isGlsFile = v82_.filename:find(".gls") ~= nil
		v82_.linkNode = v88_
		v82_.modifierTargetObject = modifierTargetObject
		v82_.current = v82_.outdoorAttributes
		v82_.audioGroup = audioGroup
		if v83_ ~= nil then
			v82_.volumeScale = v82_.volumeScale * v83_
		end
		self:createAudioSource(v82_, v82_.filename)
		v82_.offsets = {
			["volume"] = 0,
			["pitch"] = 0,
			["lowpassGain"] = 0
		}
		self.samples[v82_] = v82_
		local v90_ = self.orderedSamples
		table.insert(v90_, v82_)
	end
	return v82_
end

-- Local values: i, sample
function SoundManager:loadSamplesFromXML(xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject, samples)
	local v101_ = samples or {}
	local v102_ = 0
	while true do
		local v103_ = g_soundManager:loadSampleFromXML(xmlFile, baseKey, string.format("%s(%d)", sampleName, v102_), baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject)
		if v103_ == nil then
			break
		end
		table.insert(v101_, v103_)
		v102_ = v102_ + 1
	end
	return v101_
end

-- Local values: audioSourceName
function SoundManager:createAudioSource(sample, filename)
	if sample.soundNode ~= nil then
		delete(sample.soundNode)
	end
	if not string.isNilOrWhitespace(filename) then
		sample.filename = filename
		local v107_ = string.format("%s - %s", sample.sampleName, filename)
		sample.soundNode = createAudioSource(v107_, filename, sample.outerRadius, sample.innerRadius, sample.current.volume, sample.loops)
		sample.soundSample = getAudioSourceSample(sample.soundNode)
		self:onCreateAudioSource(sample)
	end
end

function SoundManager:onCreateAudioSource(sample, ignoreReverb)
	sample.soundSample = getAudioSourceSample(sample.soundNode)
	sample.duration = getSampleDuration(sample.soundSample)
	sample.outerRange = getAudioSourceRange(sample.soundNode)
	sample.innerRange = getAudioSourceInnerRange(sample.soundNode)
	sample.isDirty = true
	setSampleGroup(sample.soundSample, sample.audioGroup)
	setSampleVolume(sample.soundSample, sample.current.volume)
	setSamplePitch(sample.soundSample, sample.current.pitch)
	setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
	if not ignoreReverb then
		if sample.supportsReverb then
			addSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
		else
			removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
		end
	end
	setAudioSourceAutoPlay(sample.soundNode, false)
	setAudioSourcePriority(sample.soundNode, sample.priority)
	link(sample.linkNode, sample.soundNode)
	if sample.linkNodeOffset == nil then
		setTranslation(sample.soundNode, 0, 0, 0)
	else
		setTranslation(sample.soundNode, sample.linkNodeOffset[1], sample.linkNodeOffset[2], sample.linkNodeOffset[3])
	end
end

function SoundManager:createAudio2d(sample, filename)
	if sample.soundSample ~= nil then
		delete(sample.soundSample)
	end
	if not string.isNilOrWhitespace(filename) then
		sample.soundSample = createSample(sample.sampleName)
		sample.orgSoundSample = sample.soundSample
		loadSample(sample.soundSample, filename, false)
		self:onCreateAudio2d(sample)
	end
end

function SoundManager:onCreateAudio2d(sample, ignoreReverb)
	sample.duration = getSampleDuration(sample.soundSample)
	setSampleGroup(sample.soundSample, sample.audioGroup)
	setSampleVolume(sample.soundSample, sample.current.volume)
	setSamplePitch(sample.soundSample, sample.current.pitch)
	setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
	if not ignoreReverb then
		if sample.supportsReverb then
			addSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
			return
		end
		removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
	end
end

-- Local values: xmlKey, templateSample, xmlFileObject
function SoundManager:loadSampleAttributesFromTemplate(sample, templateName, baseDir, defaultLoops, xmlFile, sampleKey)
	local v122_ = self.soundTemplates[templateName]
	if v122_ == nil then
		local v123_ = g_xmlManager:getFileByHandle(xmlFile)
		if v123_ == nil then
			Logging.error("Sound template \'%s\' was not found in %s", templateName, sampleKey)
			return nil
		else
			Logging.xmlError(v123_, "Sound template \'%s\' was not found in %s", templateName, sampleKey)
			return nil
		end
	elseif self.soundTemplateXMLFile == nil then
		return sample
	else
		local v124_ = {
			["is2D"] = sample.is2D,
			["sampleName"] = sample.sampleName,
			["templateName"] = templateName
		}
		if self:loadSampleAttributesFromXML(v124_, self.soundTemplateXMLFile, v122_, baseDir, defaultLoops, false) then
			return v124_
		else
			return nil
		end
	end
end

-- Local values: parent, templateKey, priority, priorityStr, fadeIn, fadeOut
function SoundManager:loadSampleAttributesFromXML(sample, xmlFile, key, baseDir, defaultLoops, requiresFile)
	local v132_ = getXMLString(xmlFile, key .. "#parent")
	if v132_ ~= nil then
		local v133_ = self.soundTemplates[v132_]
		if v133_ ~= nil then
			self:loadSampleAttributesFromXML(sample, self.soundTemplateXMLFile, v133_, baseDir, defaultLoops, false)
		end
	end
	sample.filename = getXMLString(xmlFile, key .. "#file") or (sample.filename or "")
	if sample.filename == nil and (requiresFile == nil or requiresFile) then
		printWarning("Warning: Filename not defined in \'" .. tostring(key) .. "\'. Ignoring it!")
		return false
	end
	sample.linkNodeOffset = string.getVector(getXMLString(xmlFile, key .. "#linkNodeOffset"), 3)
	sample.innerRadius = getXMLFloat(xmlFile, key .. "#innerRadius") or (sample.innerRadius or 5)
	sample.outerRadius = getXMLFloat(xmlFile, key .. "#outerRadius") or (sample.outerRadius or 80)
	sample.volumeScale = getXMLFloat(xmlFile, key .. "#volumeScale") or (sample.volumeScale or 1)
	sample.pitchScale = getXMLFloat(xmlFile, key .. "#pitchScale") or (sample.pitchScale or 1)
	sample.lowpassGainScale = getXMLFloat(xmlFile, key .. "#lowpassGainScale") or (sample.lowpassGainScale or 1)
	sample.loopSynthesisRPMRatio = getXMLFloat(xmlFile, key .. "#loopSynthesisRPMRatio") or (sample.loopSynthesisRPMRatio or 1)
	sample.indoorAttributes = sample.indoorAttributes or {}
	sample.indoorAttributes.volume = getXMLFloat(xmlFile, key .. ".volume#indoor") or (sample.indoorAttributes.volume or 0.8)
	sample.indoorAttributes.pitch = getXMLFloat(xmlFile, key .. ".pitch#indoor") or (sample.indoorAttributes.pitch or 1)
	sample.indoorAttributes.lowpassGain = getXMLFloat(xmlFile, key .. ".lowpassGain#indoor") or (sample.indoorAttributes.lowpassGain or 0.8)
	sample.indoorAttributes.lowpassCutoffFrequency = getXMLFloat(xmlFile, key .. ".lowpassCutoffFrequency#indoor") or (sample.indoorAttributes.lowpassCutoffFrequency or 0)
	sample.indoorAttributes.lowpassResonance = getXMLFloat(xmlFile, key .. ".lowpassResonance#indoor") or (sample.indoorAttributes.lowpassResonance or 0)
	sample.outdoorAttributes = sample.outdoorAttributes or {}
	sample.outdoorAttributes.volume = getXMLFloat(xmlFile, key .. ".volume#outdoor") or (sample.outdoorAttributes.volume or 1)
	sample.outdoorAttributes.pitch = getXMLFloat(xmlFile, key .. ".pitch#outdoor") or (sample.outdoorAttributes.pitch or 1)
	sample.outdoorAttributes.lowpassGain = getXMLFloat(xmlFile, key .. ".lowpassGain#outdoor") or (sample.outdoorAttributes.lowpassGain or 1)
	sample.outdoorAttributes.lowpassCutoffFrequency = getXMLFloat(xmlFile, key .. ".lowpassCutoffFrequency#outdoor") or (sample.outdoorAttributes.lowpassCutoffFrequency or 0)
	sample.outdoorAttributes.lowpassResonance = getXMLFloat(xmlFile, key .. ".lowpassResonance#outdoor") or (sample.outdoorAttributes.lowpassResonance or 0)
	sample.loops = getXMLInt(xmlFile, key .. "#loops") or (sample.loops or (defaultLoops or 1))
	sample.supportsReverb = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsReverb"), sample.supportsReverb), true)
	sample.isLocalSound = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLocalSound"), sample.isLocalSound), false)
	local v134_ = getXMLString(xmlFile, key .. "#priority")
	local v135_
	if v134_ == nil then
		v135_ = nil
	else
		v135_ = AudioSourcePriority[string.upper(v134_)]
	end
	sample.priority = v135_ or (sample.priority or AudioSourcePriority.MEDIUM)
	sample.debug = Utils.getNoNil(getXMLBool(xmlFile, key .. "#debug"), sample.debug)
	if sample.debug or SoundManager.GLOBAL_DEBUG_ENABLED then
		if sample.debug then
			local v136_ = self.debugSamplesFlagged
			table.insert(v136_, sample)
		end
		self.debugSamples[sample] = true
		sample.debug = nil
	end
	local v137_ = getXMLFloat(xmlFile, key .. "#fadeIn")
	if v137_ ~= nil then
		v137_ = v137_ * 1000
	end
	sample.fadeIn = v137_ or (sample.fadeIn or 0)
	local v138_ = getXMLFloat(xmlFile, key .. "#fadeOut")
	if v138_ ~= nil then
		v138_ = v138_ * 1000
	end
	sample.fadeOut = v138_ or (sample.fadeOut or 0)
	sample.fade = 0
	sample.isIndoor = false
	self:loadModifiersFromXML(sample, xmlFile, key)
	self:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)
	return true
end

-- Local values: _, attribute, modifier, i, modKey, type, typeIndex, value, modifiedValue
function SoundManager:loadModifiersFromXML(sample, xmlFile, key)
	sample.modifiers = sample.modifiers or {}
	for _, v142_ in pairs(SoundManager.SAMPLE_MODIFIER_ATTRIBUTES) do
		local v143_ = sample.modifiers[v142_] or {}
		v143_.hasModification = Utils.getNoNil(v143_.hasModification, false)
		local v144_ = 0
		while true do
			local v145_ = string.format("%s.%s.modifier(%d)", key, v142_, v144_)
			if not hasXMLProperty(xmlFile, v145_) then
				break
			end
			local v146_ = getXMLString(xmlFile, v145_ .. "#type")
			local v147_ = SoundModifierType[v146_]
			if v147_ ~= nil then
				if v143_[v147_] == nil then
					v143_[v147_] = AnimCurve.new(linearInterpolator1)
				end
				local v148_ = getXMLFloat(xmlFile, v145_ .. "#value")
				local v149_ = {
					getXMLFloat(xmlFile, v145_ .. "#modifiedValue"),
					["time"] = v148_
				}
				v143_[v147_]:addKeyframe(v149_, xmlFile, v145_)
				v143_.hasModification = true
			end
			v144_ = v144_ + 1
		end
		v143_.currentValue = nil
		sample.modifiers[v142_] = v143_
	end
end

-- Local values: i, baseKey, randomization, baseKey, filename, randomSample, filename, randomSample
function SoundManager:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)
	local v155_ = 0
	while true do
		local v156_ = string.format("%s.randomization(%d)", key, v155_)
		if not hasXMLProperty(xmlFile, v156_) then
			break
		end
		local v157_ = {
			["minVolume"] = getXMLFloat(xmlFile, v156_ .. "#minVolume"),
			["maxVolume"] = getXMLFloat(xmlFile, v156_ .. "#maxVolume"),
			["minPitch"] = getXMLFloat(xmlFile, v156_ .. "#minPitch"),
			["maxPitch"] = getXMLFloat(xmlFile, v156_ .. "#maxPitch"),
			["minLowpassGain"] = getXMLFloat(xmlFile, v156_ .. "#minLowpassGain"),
			["maxLowpassGain"] = getXMLFloat(xmlFile, v156_ .. "#maxLowpassGain"),
			["isInside"] = Utils.getNoNil(getXMLBool(xmlFile, v156_ .. "#isInside"), true),
			["isOutside"] = Utils.getNoNil(getXMLBool(xmlFile, v156_ .. "#isOutside"), true)
		}
		if v157_.isInside then
			if v157_.minVolume ~= nil and sample.indoorAttributes.volume + v157_.minVolume <= 0 then
				Logging.xmlWarning(xmlFile, "Invalid sample \'%s\' randomization found in %s. randomization#minVolume can result in negative volume (indoor)", sample.templateName or sample.sampleName, v156_)
			end
			sample.randomizationsIn = sample.randomizationsIn or {}
			local v158_ = sample.randomizationsIn
			table.insert(v158_, v157_)
		end
		if v157_.isOutside then
			if v157_.minVolume ~= nil and sample.outdoorAttributes.volume + v157_.minVolume <= 0 then
				Logging.xmlWarning(xmlFile, "Invalid sample \'%s\' randomization found in %s. randomization#minVolume can result in negative volume (outdoor)", sample.templateName or sample.sampleName, v156_)
			end
			sample.randomizationsOut = sample.randomizationsOut or {}
			local v159_ = sample.randomizationsOut
			table.insert(v159_, v157_)
		end
		v155_ = v155_ + 1
	end
	local v160_ = 0
	while true do
		local v161_ = string.format("%s.sourceRandomization(%d)", key, v160_)
		if not hasXMLProperty(xmlFile, v161_) then
			break
		end
		local v162_ = getXMLString(xmlFile, v161_ .. "#file")
		if v162_ ~= nil then
			if v162_ ~= "-" then
				v162_ = Utils.getFilename(v162_, baseDir)
			end
			local v163_ = self:getRandomSample(sample, v162_)
			sample.sourceRandomizations = sample.sourceRandomizations or {}
			local v164_ = sample.sourceRandomizations
			table.insert(v164_, v163_)
		end
		v160_ = v160_ + 1
	end
	if sample.sourceRandomizations ~= nil and (#sample.sourceRandomizations > 0 and not sample.addedBaseFileToRandomizations) then
		local v165_ = self:getRandomSample(sample, (Utils.getFilename(sample.filename, baseDir)))
		local v166_ = sample.sourceRandomizations
		table.insert(v166_, v165_)
		sample.addedBaseFileToRandomizations = true
	end
end

-- Local values: randomSample, audioSourceName, audioSource, sampleId, sample2D
function SoundManager:getRandomSample(sample, filename)
	local v169_ = {
		["filename"] = filename
	}
	if filename == "-" then
		v169_.isEmpty = true
	elseif sample.is2D then
		local v170_ = createSample(sample.sampleName)
		if v170_ ~= 0 and loadSample(v170_, filename, false) then
			v169_.soundSample = v170_
			v169_.is2D = true
			return v169_
		end
	else
		local v171_ = string.format("%s - %s", sample.sampleName, filename)
		local v172_ = createAudioSource(v171_, filename, sample.outerRadius, sample.innerRadius, 1, sample.loops)
		if v172_ ~= 0 then
			v169_.soundNode = v172_
			local v173_ = getAudioSourceSample(v169_.soundNode)
			if sample.supportsReverb then
				addSampleEffect(v173_, SoundManager.DEFAULT_REVERB_EFFECT)
			else
				removeSampleEffect(v173_, SoundManager.DEFAULT_REVERB_EFFECT)
			end
			setAudioSourcePriority(v172_, sample.priority)
			return v169_
		end
	end
	return v169_
end

-- Local values: i, index, sample
function SoundManager:update(dt)
	for _ = 0, SoundManager.MAX_SAMPLES_PER_FRAME do
		local v176_ = self.currentSampleIndex
		if #self.activeSamples < v176_ then
			self.currentSampleIndex = 1
			return
		end
		local v177_ = self.activeSamples[v176_]
		if self:getIsSamplePlaying(v177_) then
			self:updateSampleFade(v177_, dt)
			self:updateSampleModifiers(v177_)
			self:updateSampleAttributes(v177_)
		else
			table.removeElement(self.activeSamples, v177_)
			v177_.fade = 0
		end
		self.currentSampleIndex = self.currentSampleIndex + 1
	end
end

-- Local values: sample, distanceToCam, x, y, fontSize, columnMaxTextWidth, activeSoundIndex, linkNode, linkNodeSamples, isVisible, linkNodeColor, linkNodeText, linkNodeName, activeSoundOffset, sample, isPlaying, sampleName, sampleColor, sx, sy, sz, text
function SoundManager:draw()
	if next(self.debugSamples) ~= nil then
		table.clear(self.debugSamplesLinkNodes)
		for v179_ in pairs(self.debugSamples) do
			if v179_.soundNode ~= nil and entityExists(v179_.soundNode) then
				local v180_ = calcDistanceFrom(g_cameraManager:getActiveCamera(), v179_.soundNode)
				if v179_.outerRadius * 2 >= v180_ or v180_ <= 15 then
					self.debugSamplesLinkNodes[v179_.linkNode] = self.debugSamplesLinkNodes[v179_.linkNode] or {}
					self.debugSamplesLinkNodes[v179_.linkNode][v179_] = true
				end
			end
		end
		local v181_ = 0.01
		local v182_ = 0.9
		local v183_ = 0
		local v184_ = 0
		for v185_, v186_ in pairs(self.debugSamplesLinkNodes) do
			local v187_ = getEffectiveVisibility(v185_)
			local v188_ = not v187_ and Color.PRESETS.RED or Color.PRESETS.WHITE
			local v189_ = string.format("LinkNode %q%s", getName(v185_), v187_ and "" or " (hidden!)")
			DebugPoint.renderAtNode(v185_, nil, v188_, false, v189_, 0.012, 250, 150)
			setTextColor(v188_:unpack())
			setTextBold(true)
			local v190_ = getName(v185_)
			renderText(v181_, v182_, 0.012, v190_)
			local v191_ = getTextWidth
			v183_ = math.max(v183_, v191_(0.012, v190_))
			local v192_ = v182_ - 0.012
			setTextColor(1, 1, 1, 1)
			setTextBold(false)
			local v193_ = 0
			for v194_ in pairs(v186_) do
				local v195_ = self:getIsSamplePlaying(v194_)
				local v196_ = v194_.templateName or Utils.getFilenameFromPath(v194_.filename)
				local v197_ = Color.PRESETS.WHITE
				if v195_ then
					local v198_, v199_, v200_ = getWorldTranslation(v194_.soundNode)
					v197_ = DebugUtil.getDebugColor(v184_)
					DebugSphere.renderAtPosition(v198_, v199_, v200_, v194_.outerRadius, v197_)
					DebugPoint.renderAtPosition(v198_, v199_, v200_, v197_, false)
					DebugText.renderAtPosition(v198_, v199_, v200_, v196_, v197_, 0.012, 0.005 + 0.012 * (v193_ + 1))
					v193_ = v193_ + 1
					v184_ = v184_ + 1
				end
				local v201_ = string.format("%q  (%d-%d)", v196_, v194_.innerRadius, v194_.outerRadius)
				setTextColor(v197_:unpack())
				renderText(v181_ + 0.012, v192_, 0.012, v201_)
				local v202_ = getTextWidth(0.012, v201_) + 0.012
				v183_ = math.max(v183_, v202_)
				v192_ = v192_ - 0.012
				if v192_ <= 0.02 then
					v181_ = v181_ + (v183_ + 0.01)
					v192_ = 0.95
					v183_ = 0
				end
			end
			v182_ = v192_ - 0.012
		end
		setTextColor(1, 1, 1, 1)
	end
end

function SoundManager:updateSampleFade(sample, dt)
	if sample ~= nil and sample.fadeIn ~= 0 then
		local v205_ = sample.fade + dt
		local v206_ = sample.fadeIn
		sample.fade = math.min(v205_, v206_)
	end
end

-- Local values: attributeIndex, attribute, modifier, value, name, typeIndex, changeValue, _, available
function SoundManager:updateSampleModifiers(sample)
	if sample ~= nil and sample.modifiers ~= nil then
		for _, v209_ in pairs(SoundManager.SAMPLE_MODIFIER_ATTRIBUTES) do
			local v210_ = sample.modifiers[v209_]
			if v210_ ~= nil then
				local v211_ = 1
				for _, v212_ in pairs(SoundModifierType) do
					local v213_, _, v214_ = self:getSampleModifierValue(sample, v209_, v212_)
					if v214_ then
						v211_ = v211_ * v213_
					end
				end
				v210_.currentValue = v211_
			end
		end
	end
end

-- Local values: volumeFactor, pitchFactor, lowpassGainFactor, loopSynthesisRpmFactor, loopSynthesisLoadFactor
function SoundManager:updateSampleAttributes(sample, force)
	if sample ~= nil then
		if sample.isIndoor ~= self.isIndoor or force then
			self:setCurrentSampleAttributes(sample, self.isIndoor)
			sample.isIndoor = self.isIndoor
		end
		if sample.soundSample ~= nil then
			local v218_ = self:getModifierFactor(sample, "volume")
			local v219_ = self:getModifierFactor(sample, "pitch")
			local v220_ = self:getModifierFactor(sample, "lowpassGain")
			setSampleVolume(sample.soundSample, v218_ * self:getCurrentSampleVolume(sample))
			setSamplePitch(sample.soundSample, v219_ * self:getCurrentSamplePitch(sample))
			setSampleFrequencyFilter(sample.soundSample, 1, v220_ * self:getCurrentSampleLowpassGain(sample), 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
			if sample.modifiers.loopSynthesisRpm.hasModification then
				local v221_ = self:getModifierFactor(sample, "loopSynthesisRpm")
				setSampleLoopSynthesisRPM(sample.soundSample, math.clamp(v221_, 0, 1), true)
			end
			if sample.modifiers.loopSynthesisLoad.hasModification then
				local v222_ = self:getModifierFactor(sample, "loopSynthesisLoad")
				setSampleLoopSynthesisLoadFactor(sample.soundSample, (math.clamp(v222_, 0, 1)))
			end
		end
	end
end

-- Local values: _, name, numRandomizations, randomizationIndexToUse, randomizationToUse, numRandomizations, randomizationIndexToUse, i, randomSample
function SoundManager:updateSampleRandomizations(sample)
	if sample ~= nil then
		for _, v225_ in ipairs(SoundManager.SAMPLE_RANDOMIZATIONS) do
			if v225_ == "randomizationsIn" == sample.isIndoor then
				local v226_ = sample[v225_] and (#sample[v225_] or 0) or 0
				if v226_ > 0 then
					local v227_ = math.random(v226_)
					local v228_ = math.floor(v227_)
					local v229_ = math.max(v228_, 1)
					local v230_ = sample[v225_][v229_]
					if v230_.minVolume ~= nil and v230_.maxVolume then
						sample[v225_].volume = math.random() * (v230_.maxVolume - v230_.minVolume) + v230_.minVolume
					end
					if v230_.minPitch ~= nil and v230_.maxPitch then
						sample[v225_].pitch = math.random() * (v230_.maxPitch - v230_.minPitch) + v230_.minPitch
					end
					if v230_.minLowpassGain ~= nil and v230_.maxLowpassGain then
						sample[v225_].lowpassGain = math.random() * (v230_.maxLowpassGain - v230_.minLowpassGain) + v230_.minLowpassGain
					end
				end
			end
		end
		local v231_ = sample.sourceRandomizations and (#sample.sourceRandomizations or 0) or 0
		if v231_ > 0 then
			local v232_ = 1
			for _ = 1, 3 do
				local v233_ = math.random(v231_)
				local v234_ = math.floor(v233_)
				v232_ = math.max(v234_, 1)
				if self.oldRandomizationIndex ~= v232_ then
					break
				end
			end
			self.oldRandomizationIndex = v232_
			local v235_ = sample.sourceRandomizations[v232_]
			if not sample.is2D then
				if sample.soundSample ~= nil then
					stopSample(sample.soundSample, 0, sample.fadeOut)
				end
				if v235_.isEmpty then
					sample.isEmptySample = true
				else
					sample.soundNode = v235_.soundNode
					self:onCreateAudioSource(sample, true)
					sample.isEmptySample = false
				end
			end
			if sample.soundSample ~= nil then
				stopSample(sample.soundSample, 0, sample.fadeOut)
			end
			if not v235_.isEmpty then
				sample.soundSample = v235_.soundSample
				self:onCreateAudio2d(sample, true)
				sample.isEmptySample = false
				return
			end
			sample.isEmptySample = true
		end
	end
end

-- Local values: modifier, curve, typeData, t, min
function SoundManager:getSampleModifierValue(sample, attribute, typeIndex)
	local v240_ = sample.modifiers[attribute]
	if v240_ ~= nil then
		local v241_ = v240_[typeIndex]
		if v241_ ~= nil then
			local v242_ = self.modifierTypeIndexToDesc[typeIndex]
			local v243_ = v242_.func(sample.modifierTargetObject)
			if v242_.maxFunc ~= nil and v242_.minFunc ~= nil then
				local v244_ = v242_.minFunc(sample.modifierTargetObject)
				local v245_ = (v243_ - v244_) / (v242_.maxFunc(sample.modifierTargetObject) - v244_)
				v243_ = math.clamp(v245_, 0, 1)
			end
			return v241_:get(v243_), v243_, true
		end
	end
	return 0, 0, false
end

-- Local values: _, randomSample
function SoundManager:deleteSample(sample)
	if sample ~= nil and sample.filename ~= nil then
		if self:getIsSamplePlaying(sample) then
			self:stopSample(sample)
		end
		self.samples[sample] = nil
		table.removeElement(self.activeSamples, sample)
		table.removeElement(self.orderedSamples, sample)
		self.debugSamples[sample] = nil
		table.removeElement(self.debugSamplesFlagged, sample)
		if sample.soundNode ~= nil then
			delete(sample.soundNode)
		end
		if sample.is2D and sample.orgSoundSample ~= nil then
			delete(sample.orgSoundSample)
		end
		if sample.sourceRandomizations ~= nil then
			for _, v248_ in ipairs(sample.sourceRandomizations) do
				if not v248_.isEmpty then
					if v248_.soundNode ~= nil and v248_.soundNode ~= sample.soundNode then
						delete(v248_.soundNode)
					end
					if v248_.is2D then
						delete(v248_.soundSample)
					end
				end
			end
			sample.sourceRandomizations = nil
		end
		sample.soundSample = nil
		sample.soundNode = nil
	end
end

-- Local values: _, sample
function SoundManager:deleteSamples(samples, delay, afterSample)
	if samples ~= nil then
		for _, v253_ in pairs(samples) do
			self:deleteSample(v253_, delay, afterSample)
		end
	end
end

-- Local values: afterSampleId
function SoundManager:playSample(sample, delay, afterSample)
	if sample ~= nil and (not sample.isLocalSound or (sample.modifierTargetObject == nil or sample.isLocalSound and sample.modifierTargetObject.isActiveForLocalSound)) then
		self:updateSampleRandomizations(sample)
		self:updateSampleModifiers(sample)
		self:updateSampleAttributes(sample, true)
		if not sample.isEmptySample and sample.soundSample ~= nil then
			local v258_ = afterSample == nil and 0 or afterSample.soundSample
			playSample(sample.soundSample, sample.loops, self:getModifierFactor(sample, "volume") * self:getCurrentSampleVolume(sample), 0, delay or 0, v258_)
			table.addElement(self.activeSamples, sample)
		end
	end
end

-- Local values: _, sample
function SoundManager:playSamples(samples, delay, afterSample)
	for _, v263_ in pairs(samples) do
		self:playSample(v263_, delay, afterSample)
	end
end

function SoundManager:stopSample(sample, delay, fadeOut)
	if sample ~= nil and sample.soundSample ~= nil then
		stopSample(sample.soundSample, delay or getSampleLoopSynthesisStopDuration(sample.soundSample), fadeOut or sample.fadeOut)
	end
end

-- Local values: _, sample
function SoundManager:stopSamples(samples)
	for _, v269_ in pairs(samples) do
		self:stopSample(v269_)
	end
end

function SoundManager:setSampleVolumeOffset(sample, offset)
	if sample ~= nil then
		sample.offsets.volume = offset
	end
end

function SoundManager:setSamplePitchOffset(sample, offset)
	if sample ~= nil then
		sample.offsets.pitch = offset
	end
end

function SoundManager:setSampleLowpassGainOffset(sample, offset)
	if sample ~= nil then
		sample.offsets.lowpassGain = offset
	end
end

function SoundManager:setSampleVolume(sample, volume)
	if sample ~= nil and sample.soundSample ~= nil then
		setSampleVolume(sample.soundSample, volume)
	end
end

function SoundManager:setSampleVolumeScale(sample, volumeScale)
	if sample ~= nil then
		sample.volumeScale = volumeScale
	end
end

function SoundManager:getSampleVolumeScale(sample)
	return sample == nil and 1 or sample.volumeScale
end

function SoundManager:setSamplePitch(sample, pitch)
	if sample ~= nil and sample.soundSample ~= nil then
		setSamplePitch(sample.soundSample, pitch)
	end
end

function SoundManager:getIsSamplePlaying(sample)
	if sample == nil or sample.soundSample == nil then
		return false
	else
		return isSamplePlaying(sample.soundSample)
	end
end

function SoundManager:getSamplePlayOffset(sample)
	return (sample == nil or sample.soundSample == nil) and 0 or getSamplePlayOffset(sample.soundSample)
end

function SoundManager:setSampleLoopSynthesisParameters(sample, rpm, loadFactor)
	if sample ~= nil and sample.soundSample ~= nil then
		if rpm ~= nil then
			if sample.loopSynthesisRPMRatio ~= 1 then
				local v288_ = rpm / sample.loopSynthesisRPMRatio
				rpm = math.clamp(v288_, 0, 1)
			end
			setSampleLoopSynthesisRPM(sample.soundSample, rpm, true)
		end
		if loadFactor ~= nil then
			setSampleLoopSynthesisLoadFactor(sample.soundSample, loadFactor)
		end
	end
end

-- Local values: _, sample
function SoundManager:setSamplesLoopSynthesisParameters(samples, rpm, loadFactor)
	for _, v293_ in pairs(samples) do
		self:setSampleLoopSynthesisParameters(v293_, rpm, loadFactor)
	end
end

function SoundManager:getSampleLoopSynthesisStartDuration(sample)
	return (sample == nil or (sample.soundSample == nil or not sample.isGlsFile)) and 0 or getSampleLoopSynthesisStartDuration(sample.soundSample)
end

function SoundManager:setCurrentSampleAttributes(sample, isIndoor)
	if isIndoor then
		sample.current = sample.indoorAttributes
		sample.randomizations = sample.randomizationsIn
	else
		sample.current = sample.outdoorAttributes
		sample.randomizations = sample.randomizationsOut
	end
end

function SoundManager:getCurrentSampleVolume(sample)
	local v299_ = (sample.current.volume + self:getCurrentRandomizationValue(sample, "volume")) * self:getCurrentFadeFactor(sample) * sample.volumeScale + sample.offsets.volume
	return math.max(v299_, 0)
end

function SoundManager:getCurrentSamplePitch(sample)
	return (sample.current.pitch + self:getCurrentRandomizationValue(sample, "pitch")) * sample.pitchScale + sample.offsets.pitch
end

function SoundManager:getCurrentSampleLowpassGain(sample)
	return (sample.current.lowpassGain + self:getCurrentRandomizationValue(sample, "lowpassGain")) * sample.lowpassGainScale + sample.offsets.lowpassGain
end

function SoundManager:getCurrentRandomizationValue(sample, attribute)
	return (sample.randomizations == nil or sample.randomizations[attribute] == nil) and 0 or sample.randomizations[attribute]
end

-- Local values: fadeFactor
function SoundManager:getCurrentFadeFactor(sample)
	return sample.fadeIn == 0 and 1 or sample.fade / sample.fadeIn
end

-- Local values: i, sample, _, target
function SoundManager:setIsIndoor(isIndoor)
	if self.isIndoor ~= isIndoor then
		self.isIndoor = isIndoor
		for v309_ = 1, #self.activeSamples do
			local v310_ = self.activeSamples[v309_]
			if self:getIsSamplePlaying(v310_) then
				self:updateSampleAttributes(v310_)
			end
		end
		for _, v311_ in ipairs(self.indoorStateChangedListeners) do
			v311_:onIndoorStateChanged(isIndoor)
		end
	end
end

function SoundManager:addIndoorStateChangedListener(target)
	table.addElement(self.indoorStateChangedListeners, target)
end

function SoundManager:removeIndoorStateChangedListener(target)
	table.removeElement(self.indoorStateChangedListeners, target)
end

function SoundManager:getIsIndoor()
	return self.isIndoor
end

-- Local values: modifier
function SoundManager:getModifierFactor(sample, modifierName)
	if sample.modifiers ~= nil then
		local v319_ = sample.modifiers[modifierName]
		if v319_ ~= nil and v319_.currentValue ~= nil then
			return v319_.currentValue
		end
	end
	return 1
end

-- Local values: _, sample, _, sample
function SoundManager:consoleCommandToggleDebug()
	SoundManager.GLOBAL_DEBUG_ENABLED = not SoundManager.GLOBAL_DEBUG_ENABLED
	if SoundManager.GLOBAL_DEBUG_ENABLED then
		for _, v321_ in pairs(self.orderedSamples) do
			if v321_.linkNode ~= nil then
				self.debugSamples[v321_] = true
			end
		end
	else
		table.clear(self.debugSamples)
		for _, v322_ in pairs(self.debugSamplesFlagged) do
			self.debugSamples[v322_] = true
		end
	end
	return string.format("SoundManager.GLOBAL_DEBUG_ENABLED=%s", SoundManager.GLOBAL_DEBUG_ENABLED)
end

function SoundManager.registerModifierXMLPaths(schema, path)
	local v325_ = XMLValueType.STRING
	local v326_ = path .. ".modifier(?)#type"
	local v327_ = "Modifier type"
	local v328_ = nil
	local v329_ = false
	local v330_ = SoundModifierType
	if v330_ then
		v330_ = table.toList(SoundModifierType)
	end
	schema:register(v325_, v326_, v327_, v328_, v329_, v330_)
	schema:register(XMLValueType.FLOAT, path .. ".modifier(?)#value", "Source value of modifier type")
	schema:register(XMLValueType.FLOAT, path .. ".modifier(?)#modifiedValue", "Change that is applied on sample value")
end

-- Local values: soundPath
function SoundManager.registerSampleXMLPaths(schema, basePath, xmlElementName)
	schema:setSubSchemaIdentifier("sounds")
	if xmlElementName == nil then
		Logging.error("Failed to register sound sample xml paths! No sound xml element name given.")
		printCallstack()
		return
	elseif string.contains(xmlElementName, " ") then
		Logging.error("Failed to register sound sample xml paths! XML element name cannot have spaces: \'%s\'", xmlElementName)
		printCallstack()
	else
		schema:setXMLSharedRegistration("SoundManager_sound", basePath)
		local v334_ = basePath .. "." .. xmlElementName
		schema:register(XMLValueType.NODE_INDEX, v334_ .. "#linkNode", "Link node for 3d sound")
		schema:register(XMLValueType.VECTOR_TRANS, v334_ .. "#linkNodeOffset", "Sound source will be offset by this value to the link node")
		schema:register(XMLValueType.STRING, v334_ .. "#template", "Sound template name")
		schema:registerAutoCompletionDataSource(v334_ .. "#template", "$data/sounds/soundTemplates.xml", "soundTemplates.template#name")
		SoundManager.registerGenericSampleXMLPaths(schema, v334_)
		schema:resetXMLSharedRegistration("SoundManager_sound", basePath)
		schema:setSubSchemaIdentifier()
	end
end

function SoundManager.registerGenericSampleXMLPaths(schema, soundPath)
	schema:register(XMLValueType.STRING, soundPath .. "#parent", "Parent sample for inheritance")
	schema:register(XMLValueType.STRING, soundPath .. "#file", "Path to sound sample")
	schema:register(XMLValueType.FLOAT, soundPath .. "#outerRadius", "Outer radius", 5)
	schema:register(XMLValueType.FLOAT, soundPath .. "#innerRadius", "Inner radius", 80)
	schema:register(XMLValueType.INT, soundPath .. "#loops", "Number of loops (0 = infinite)", 1)
	schema:register(XMLValueType.BOOL, soundPath .. "#supportsReverb", "Flag to disable reverb", true)
	schema:register(XMLValueType.BOOL, soundPath .. "#isLocalSound", "While set for vehicle sounds it will only play for the player currently using the vehicle", false)
	schema:register(XMLValueType.STRING, soundPath .. "#priority", "Priority of the sound", "MEDIUM", false, EnumUtil.getKeys(AudioSourcePriority))
	schema:register(XMLValueType.BOOL, soundPath .. "#debug", "Flag to enable debug rendering", false)
	schema:register(XMLValueType.FLOAT, soundPath .. "#fadeIn", "Fade in time in seconds", 0)
	schema:register(XMLValueType.FLOAT, soundPath .. "#fadeOut", "Fade out time in seconds", 0)
	schema:register(XMLValueType.FLOAT, soundPath .. ".volume#indoor", "Indoor volume", 0.8)
	schema:register(XMLValueType.FLOAT, soundPath .. ".pitch#indoor", "Indoor pitch", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassGain#indoor", "Indoor lowpass gain", 0.8)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassCutoffFrequency#indoor", "Indoor lowpass cutoff frequency", 5000)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassResonance#indoor", "Indoor lowpass resonance", 2)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassCutoffFrequency#outdoor", "Outdoor lowpass cutoff frequency", 5000)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassResonance#outdoor", "Outdoor lowpass resonance", 2)
	schema:register(XMLValueType.FLOAT, soundPath .. ".volume#outdoor", "Outdoor volume", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. ".pitch#outdoor", "Outdoor pitch", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassGain#outdoor", "Outdoor lowpass gain", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#volumeScale", "Additional scale that is applied on the volume attributes", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#pitchScale", "Additional pitch that is applied on the volume attributes", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#lowpassGainScale", "Additional lowpass gain that is applied on the volume attributes", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#loopSynthesisRPMRatio", "Ratio between rpm in the gls file and actual rpm of the motor (e.g. 0.9: max. rpm in the gls file will be reached at 90% of motor rpm)", 1)
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".volume")
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".pitch")
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".lowpassGain")
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".loopSynthesisRpm")
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".loopSynthesisLoad")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minVolume", "Min volume")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxVolume", "Max volume")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minPitch", "Max pitch")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxPitch", "Max pitch")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minLowpassGain", "Max lowpass gain")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxLowpassGain", "Max lowpass gain")
	schema:register(XMLValueType.BOOL, soundPath .. ".randomization(?)#isInside", "Randomization is applied inside", true)
	schema:register(XMLValueType.BOOL, soundPath .. ".randomization(?)#isOutside", "Randomization is applied outside", true)
	schema:register(XMLValueType.STRING, soundPath .. ".sourceRandomization(?)#file", "Path to sound sample")
end
if g_xmlManager ~= nil then
	g_xmlManager:addCreateSchemaFunction(function()
		SoundManager.soundTemplatesXmlSchema = XMLSchema.new("soundTemplates")
		SoundManager.soundTemplatesXmlSchema.supportsParentFile = false
	end)
	g_xmlManager:addInitSchemaFunction(function()
		local v337_ = SoundManager.soundTemplatesXmlSchema
		v337_:register(XMLValueType.STRING, "soundTemplates.template(?)#name", "Name of the sound template", nil, true)
		SoundManager.registerGenericSampleXMLPaths(v337_, "soundTemplates.template(?)")
	end)
end
