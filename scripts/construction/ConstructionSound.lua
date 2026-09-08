-- Local values: ConstructionSound_mt
ConstructionSound = {}
local ConstructionSound_mt = Class(ConstructionSound)
ConstructionSound.ID = {}
ConstructionSound.ID.NONE = 0
ConstructionSound.ID.TREE = 1
ConstructionSound.ID.SCULPT = 2
ConstructionSound.ID.PAINT = 3
ConstructionSound.ID.FOLIAGE = 4

-- Upvalues: ConstructionSound_mt
-- Local values: self
function ConstructionSound.new(subclass_mt)
	-- upvalues: (copy) ConstructionSound_mt
	local v3_ = subclass_mt or ConstructionSound_mt
	local v4_ = setmetatable({}, v3_)
	v4_.currentActiveSoundId = ConstructionSound.ID.NONE
	v4_.samples = v4_:loadSamples("dataS/constructionSoundSamples.xml")
	return v4_
end

-- Local values: samples, xmlFile, key, id, loops, sample
function ConstructionSound:loadSamples(xmlPath)
	local v6_ = {}
	local v7_ = XMLFile.load("constructionSound", xmlPath)
	if v7_ == nil then
		return v6_
	end
	for v8_, v9_ in pairs(ConstructionSound.ID) do
		if v9_ ~= ConstructionSound.ID.NONE then
			local v10_ = v7_:getInt("constructionSoundSamples." .. v8_ .. "#loops", 0)
			local v11_ = g_soundManager:loadSample2DFromXML(v7_.handle, "constructionSoundSamples", string.lower(v8_), "", v10_, AudioGroup.GUI)
			if v11_ == nil then
				Logging.warning("Could not load construction sound sample [%s]", v8_)
			else
				v6_[v9_] = v11_
			end
		end
	end
	v7_:delete()
	return v6_
end

-- Local values: k, sample
function ConstructionSound:delete()
	for v13_, v14_ in pairs(self.samples) do
		g_soundManager:deleteSample(v14_)
		self.samples[v13_] = nil
	end
end

-- Local values: isOneOff, oldSample, newSample, isOldOneOff, isNewOneOff, sample, pitch
function ConstructionSound:setActiveSound(soundId, pitchModifier)
	local v18_
	if soundId == self.currentActiveSoundId then
		v18_ = false
	else
		if soundId == ConstructionSound.ID.NONE and not self.silenceQueued then
			self.silenceQueued = true
			return
		end
		self.silenceQueued = false
		local v19_ = self.samples[self.currentActiveSoundId]
		local v20_ = self.samples[soundId]
		local v21_
		if v19_ == nil then
			v21_ = false
		else
			v21_ = v19_.loops == 1
		end
		if v20_ == nil then
			v18_ = false
		else
			v18_ = v20_.loops == 1
		end
		if not v21_ then
			g_soundManager:stopSample(v19_)
		end
		g_soundManager:playSample(v20_)
		self.currentActiveSoundId = soundId
	end
	local v22_ = self.samples[self.currentActiveSoundId]
	if v22_ ~= nil then
		local v23_ = pitchModifier == nil and 1 or MathUtil.smoothstep(0, 1, pitchModifier) + 0.5
		v22_.current.pitch = v23_
	end
	return v18_
end
