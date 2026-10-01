ConstructionSound = {}
local ConstructionSound_mt = Class(ConstructionSound)
ConstructionSound.ID = {}
ConstructionSound.ID.NONE = 0
ConstructionSound.ID.TREE = 1
ConstructionSound.ID.SCULPT = 2
ConstructionSound.ID.PAINT = 3
ConstructionSound.ID.FOLIAGE = 4
function ConstructionSound.new(subclass_mt)
	local self = setmetatable({}, subclass_mt or ConstructionSound_mt)
	self.currentActiveSoundId = ConstructionSound.ID.NONE
	self.samples = self:loadSamples("dataS/constructionSoundSamples.xml")
	return self
end
function ConstructionSound:loadSamples(xmlPath)
	local samples = {}
	local xmlFile = XMLFile.load("constructionSound", xmlPath)
	if xmlFile == nil then
		return samples
	else
		for key, id in pairs(ConstructionSound.ID) do
			if id == ConstructionSound.ID.NONE then
				continue
			end
			local loops = xmlFile:getInt("constructionSoundSamples." .. key .. "#loops", 0)
			local sample = g_soundManager:loadSample2DFromXML(xmlFile.handle, "constructionSoundSamples", string.lower(key), "", loops, AudioGroup.GUI)
			if sample ~= nil then
				samples[id] = sample
			else
				Logging.warning("Could not load construction sound sample [%s]", key)
			end
		end
		xmlFile:delete()
		return samples
	end
end
function ConstructionSound:delete()
	for k, sample in pairs(self.samples) do
		g_soundManager:deleteSample(sample)
		self.samples[k] = nil
	end
end
function ConstructionSound:setActiveSound(soundId, pitchModifier)
	local isOneOff = false
	if soundId ~= self.currentActiveSoundId then
		if soundId == ConstructionSound.ID.NONE and not self.silenceQueued then
			self.silenceQueued = true
			return
		end
		self.silenceQueued = false
		local oldSample = self.samples[self.currentActiveSoundId]
		local newSample = self.samples[soundId]
		local isOldOneOff = oldSample ~= nil and oldSample.loops == 1
		local isNewOneOff = newSample ~= nil and newSample.loops == 1
		if not isOldOneOff then
			g_soundManager:stopSample(oldSample)
		end
		g_soundManager:playSample(newSample)
		self.currentActiveSoundId = soundId
		isOneOff = isNewOneOff
	end
	local sample = self.samples[self.currentActiveSoundId]
	if sample ~= nil then
		local pitch = 1
		if pitchModifier ~= nil then
			pitch = MathUtil.smoothstep(0, 1, pitchModifier) + 0.5
		end
		sample.current.pitch = pitch
	end
	return isOneOff
end
