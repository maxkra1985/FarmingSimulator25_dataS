ServerSoundManager = {}
local ServerSoundManager_mt = Class(ServerSoundManager, SoundManager)
function ServerSoundManager.new(customMt)
	local self = SoundManager.new(customMt or ServerSoundManager_mt)
	return self
end
function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
	local newSample = table.clone(sample)
	newSample.modifiers = table.clone(sample.modifiers)
	if modifierTargetObject ~= nil then
		newSample.modifierTargetObject = modifierTargetObject
	end
	newSample.sourceRandomizations = {}
	self.samples[newSample] = newSample
	table.insert(self.orderedSamples, newSample)
	return newSample
end
function SoundManager:cloneSample2D(sample, linkNode, modifierTargetObject)
	local newSample = table.clone(sample)
	newSample.modifiers = table.clone(sample.modifiers)
	newSample.audioGroup = sample.audioGroup
	newSample.linkNode = nil
	newSample.soundNode = nil
	newSample.is2D = true
	if modifierTargetObject ~= nil then
		newSample.modifierTargetObject = modifierTargetObject
	end
	self.samples[newSample] = newSample
	table.insert(self.orderedSamples, newSample)
	return newSample
end
function ServerSoundManager:createAudioSource(sample, filename)
	sample.soundSample = nil
	sample.duration = 0
	sample.outerRange = 0
	sample.innerRange = 0
	sample.isDirty = false
end
function ServerSoundManager:createAudio2d(sample, filename)
	sample.soundSample = nil
	sample.duration = 0
end
function ServerSoundManager:update(dt) end
function ServerSoundManager:draw() end
function ServerSoundManager:playSample(sample, delay, afterSample)
	if sample ~= nil then
		sample.isPlaying = sample.loops == 0
	end
end
function ServerSoundManager:playSamples(samples, delay, afterSample)
	for _, sample in pairs(samples) do
		self:playSample(sample, delay, afterSample)
	end
end
function ServerSoundManager:stopSample(sample, delay, fadeOut)
	if sample ~= nil then
		sample.isPlaying = false
	end
end
function ServerSoundManager:stopSamples(samples)
	for _, sample in pairs(samples) do
		self:stopSample(sample)
	end
end
function ServerSoundManager:getIsSamplePlaying(sample)
	if sample ~= nil then
		return sample.isPlaying
	else
		return false
	end
end
