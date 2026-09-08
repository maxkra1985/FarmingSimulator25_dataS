-- Local values: WildlifeInstanceSounds_mt
WildlifeInstanceSounds = {}
local WildlifeInstanceSounds_mt = Class(WildlifeInstanceSounds)

function WildlifeInstanceSounds.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.STRING, "species.sounds.sound(?)#name", "The name of the sound group", nil, true)
	xmlSchema:register(XMLValueType.FLOAT, "species.sounds.sound(?)#cooldown", "The time in seconds in which the same sound group cannot be played more than once", 0, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.sounds.sound(?)#chance", "The chance of the sound playing", 1, false)
end

-- Upvalues: WildlifeInstanceSounds_mt
-- Local values: self
function WildlifeInstanceSounds.new(instance)
	-- upvalues: (copy) WildlifeInstanceSounds_mt
	local v4_ = WildlifeInstanceSounds_mt
	local v5_ = setmetatable({}, v4_)
	v5_.instance = instance
	v5_.soundPlayedTimestamps = {}
	v5_.currentSample = nil
	return v5_
end

function WildlifeInstanceSounds:delete()
	table.clear(self.soundPlayedTimestamps)
	self:deleteCurrentSample(true)
end

function WildlifeInstanceSounds:deleteCurrentSample(skipPlayingCheck)
	if self.currentSample == nil then
		return false
	end
	if not skipPlayingCheck and g_soundManager:getIsSamplePlaying(self.currentSample) then
		return false
	end
	g_soundManager:deleteSample(self.currentSample)
	self.currentSample = nil
	return true
end

function WildlifeInstanceSounds:onInstanceSpawned(species)
	table.clear(self.soundPlayedTimestamps)
	self:deleteCurrentSample(true)
end

-- Local values: soundGroup, lastPlayedTimestamp, timeSinceLastPlayed, playChance
function WildlifeInstanceSounds:playSound(soundGroupName, chanceOverride)
	if self.currentSample == nil or self:deleteCurrentSample() then
		local v13_ = self.instance.species.soundAttributes.soundGroups[soundGroupName]
		if v13_ == nil or #v13_ == 0 then
			return
		else
			local v14_ = self.soundPlayedTimestamps[soundGroupName] or 0
			if g_time - v14_ < v13_.cooldown then
				return
			elseif (chanceOverride or (v13_.chance or 1)) >= math.random() then
				self.currentSample = g_soundManager:cloneSample(v13_[math.random(#v13_)], self.instance.rootNode)
				g_soundManager:playSample(self.currentSample)
				self.soundPlayedTimestamps[soundGroupName] = g_time
			end
		end
	else
		return
	end
end

-- Local values: attributes, _modName, baseDirectory, soundGroupIndex, soundGroupKey, soundGroup, sampleIndex, sampleKey, sample
function WildlifeInstanceSounds.loadAttributesTable(xmlFile)
	local v16_ = {
		["linkNode"] = createTransformGroup("soundNode")
	}
	local _, v17_ = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
	v16_.soundGroups = {}
	for _, v18_ in xmlFile:iterator("species.sounds.sound") do
		local v19_ = {
			["name"] = xmlFile:getValue(v18_ .. "#name"),
			["cooldown"] = xmlFile:getValue(v18_ .. "#cooldown", 0),
			["chance"] = xmlFile:getValue(v18_ .. "#chance", 1)
		}
		v16_.soundGroups[v19_.name] = v19_
		for v20_, _ in xmlFile:iterator(v18_ .. ".sample") do
			local v21_ = g_soundManager:loadSampleFromXML(xmlFile, v18_, string.format("sample(%d)", v20_), v17_, v16_.linkNode, 1, AudioGroup.ENVIRONMENT, nil, nil)
			table.insert(v19_, v21_)
		end
	end
	return v16_
end

-- Local values: _, soundGroup, _, sound
function WildlifeInstanceSounds.deleteAttributesTable(attributes)
	for _, v23_ in ipairs(attributes) do
		for _, v24_ in ipairs(v23_) do
			g_soundManager:deleteSample(v24_.sample)
		end
	end
	delete(attributes.linkNode)
end
