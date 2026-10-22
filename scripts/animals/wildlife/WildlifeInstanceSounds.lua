WildlifeInstanceSounds = {}
local WildlifeInstanceSounds_mt = Class(WildlifeInstanceSounds)
function WildlifeInstanceSounds.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.STRING, "species.sounds.sound(?)#name", "The name of the sound group", nil, true)
	xmlSchema:register(XMLValueType.FLOAT, "species.sounds.sound(?)#cooldown", "The time in seconds in which the same sound group cannot be played more than once", 0, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.sounds.sound(?)#chance", "The chance of the sound playing", 1, false)
	SoundManager.registerSampleXMLPaths(xmlSchema, "species.sounds.sound(?)", "sample(?)")
end
function WildlifeInstanceSounds.new(instance)
	local self = setmetatable({}, WildlifeInstanceSounds_mt)
	self.instance = instance
	self.soundPlayedTimestamps = {}
	self.currentSample = nil
	return self
end
function WildlifeInstanceSounds:delete()
	table.clear(self.soundPlayedTimestamps)
	self:deleteCurrentSample(true)
end
function WildlifeInstanceSounds:deleteCurrentSample(skipPlayingCheck)
	if self.currentSample == nil then
		return false
	elseif not skipPlayingCheck and g_soundManager:getIsSamplePlaying(self.currentSample) then
		return false
	else
		g_soundManager:deleteSample(self.currentSample)
		self.currentSample = nil
		return true
	end
end
function WildlifeInstanceSounds:onInstanceSpawned(species)
	table.clear(self.soundPlayedTimestamps)
	self:deleteCurrentSample(true)
end
function WildlifeInstanceSounds:playSound(soundGroupName, chanceOverride)
	if self.currentSample ~= nil and not self:deleteCurrentSample() then
		return
	end
	local soundAttributes = self.instance.species.soundAttributes
	if soundAttributes == nil then
		return
	end
	local soundGroup = soundAttributes.soundGroups[soundGroupName]
	if soundGroup == nil or #soundGroup == 0 then
		return
	end
	local lastPlayedTimestamp = self.soundPlayedTimestamps[soundGroupName] or 0
	local timeSinceLastPlayed = g_time - lastPlayedTimestamp
	if timeSinceLastPlayed < soundGroup.cooldown then
		return
	end
	local playChance = chanceOverride or soundGroup.chance or 1
	if playChance < math.random() then
		return
	else
		self.currentSample = g_soundManager:cloneSample(soundGroup[math.random(#soundGroup)], self.instance.rootNode)
		g_soundManager:playSample(self.currentSample)
		self.soundPlayedTimestamps[soundGroupName] = g_time
	end
end
function WildlifeInstanceSounds.loadAttributesTable(xmlFile)
	local attributes = {}
	attributes.linkNode = createTransformGroup("soundNode")
	local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
	attributes.soundGroups = {}
	for _, soundGroupKey in xmlFile:iterator("species.sounds.sound") do
		local name = xmlFile:getString(soundGroupKey .. "#name")
		if name == nil then
			Logging.xmlWarning(xmlFile, "Missing name for sound group '%s'", soundGroupKey)
		else
			local soundGroup = {}
			soundGroup.name = name
			soundGroup.cooldown = xmlFile:getFloat(soundGroupKey .. "#cooldown", 0) * 1000
			soundGroup.chance = xmlFile:getFloat(soundGroupKey .. "#chance", 1)
			attributes.soundGroups[name] = soundGroup
			for sampleIndex, _ in xmlFile:iterator(soundGroupKey .. ".sample") do
				local sampleName = string.format("sample(%d)", sampleIndex - 1)
				local sample = g_soundManager:loadSampleFromXML(xmlFile, soundGroupKey, sampleName, baseDirectory, attributes.linkNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
				if sample == nil then
					continue
				end
				table.insert(soundGroup, sample)
			end
		end
	end
	return attributes
end
function WildlifeInstanceSounds.deleteAttributesTable(attributes)
	for _, soundGroup in pairs(attributes.soundGroups) do
		for _, sample in ipairs(soundGroup) do
			g_soundManager:deleteSample(sample)
		end
	end
	delete(attributes.linkNode)
end
