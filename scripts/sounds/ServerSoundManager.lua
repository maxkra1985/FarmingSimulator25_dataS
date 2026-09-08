-- Local values: ServerSoundManager_mt
ServerSoundManager = {}
local ServerSoundManager_mt = Class(ServerSoundManager, SoundManager)

-- Upvalues: ServerSoundManager_mt
-- Local values: self
function ServerSoundManager.new(customMt)
	-- upvalues: (copy) ServerSoundManager_mt
	return SoundManager.new(customMt or ServerSoundManager_mt)
end

-- Local values: newSample
function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
	local v6_ = table.clone(sample)
	v6_.modifiers = table.clone(sample.modifiers)
	if modifierTargetObject ~= nil then
		v6_.modifierTargetObject = modifierTargetObject
	end
	v6_.sourceRandomizations = {}
	self.samples[v6_] = v6_
	local v7_ = self.orderedSamples
	table.insert(v7_, v6_)
	return v6_
end

-- Local values: newSample
function SoundManager:cloneSample2D(sample, linkNode, modifierTargetObject)
	local v11_ = table.clone(sample)
	v11_.modifiers = table.clone(sample.modifiers)
	v11_.audioGroup = sample.audioGroup
	v11_.linkNode = nil
	v11_.soundNode = nil
	v11_.is2D = true
	if modifierTargetObject ~= nil then
		v11_.modifierTargetObject = modifierTargetObject
	end
	self.samples[v11_] = v11_
	local v12_ = self.orderedSamples
	table.insert(v12_, v11_)
	return v11_
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

-- Local values: _, sample
function ServerSoundManager:playSamples(samples, delay, afterSample)
	for _, v20_ in pairs(samples) do
		self:playSample(v20_, delay, afterSample)
	end
end

function ServerSoundManager:stopSample(sample, delay, fadeOut)
	if sample ~= nil then
		sample.isPlaying = false
	end
end

-- Local values: _, sample
function ServerSoundManager:stopSamples(samples)
	for _, v24_ in pairs(samples) do
		self:stopSample(v24_)
	end
end

function ServerSoundManager:getIsSamplePlaying(sample)
	if sample == nil then
		return false
	else
		return sample.isPlaying
	end
end
