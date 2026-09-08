-- Local values: GuiSoundPlayer_mt
GuiSoundPlayer = {}
local GuiSoundPlayer_mt = Class(GuiSoundPlayer)
GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH = "dataS/gui/guiSoundSamples.xml"
GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT = "GuiSoundSamples"
GuiSoundPlayer.NUM_SAMPLES_PER_SOUND = 3
GuiSoundPlayer.SAMPLE_REPLAY_TIMEOUT = 25
GuiSoundPlayer.SOUND_SAMPLES = {
	["NONE"] = "",
	["CLICK"] = "click",
	["BACK"] = "back",
	["HOVER"] = "hover",
	["ERROR"] = "error",
	["PAGING"] = "paging",
	["TRANSACTION"] = "transaction",
	["SUCCESS"] = "success",
	["FAIL"] = "fail",
	["ACHIEVEMENT"] = "achievement",
	["NOTIFICATION"] = "notification",
	["COLLECTIBLE"] = "collectible",
	["COLLECTIBLE_BOOK"] = "collectibleBook",
	["START"] = "start",
	["MAP"] = "map",
	["CALENDAR"] = "calendar",
	["ANIMALS"] = "animals",
	["CONTRACTS"] = "contracts",
	["PRODUCTIONS"] = "productions",
	["STATISTICS"] = "statistics",
	["SETTIGNS"] = "settings",
	["MULTIPLAYER"] = "multiplayer",
	["CONFIG_SPRAY"] = "configSpray",
	["CONFIG_WRENCH"] = "configWrench",
	["YES"] = "yes",
	["NO"] = "no",
	["QUERY"] = "query",
	["TEXTBOX"] = "textbox",
	["SELECT"] = "select"
}

-- Upvalues: GuiSoundPlayer_mt
-- Local values: self
function GuiSoundPlayer.new(soundManager)
	-- upvalues: (copy) GuiSoundPlayer_mt
	local v3_ = GuiSoundPlayer_mt
	local v4_ = setmetatable({}, v3_)
	v4_.soundManager = soundManager
	v4_.soundSamples = v4_:loadSounds(GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH)
	return v4_
end

-- Local values: _, samples, _, sample
function GuiSoundPlayer:delete()
	for _, v6_ in pairs(self.soundSamples) do
		for _, v7_ in ipairs(v6_) do
			self.soundManager:deleteSample(v7_)
		end
	end
	self.soundSamples = {}
end

-- Local values: samples, xmlFile, _, key, sample, sampleList, i
function GuiSoundPlayer:loadSounds(sampleDefinitionXmlPath)
	local v10_ = {}
	local v11_ = loadXMLFile("GuiSampleDefinitions", sampleDefinitionXmlPath)
	if v11_ ~= nil and v11_ ~= 0 then
		for _, v12_ in pairs(GuiSoundPlayer.SOUND_SAMPLES) do
			if v12_ ~= GuiSoundPlayer.SOUND_SAMPLES.NONE then
				local v13_ = self.soundManager:loadSample2DFromXML(v11_, GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT, v12_, "", 1, AudioGroup.GUI)
				if v13_ == nil then
					printWarning("Warning: Could not load GUI sound sample [" .. tostring(v12_) .. "]")
				else
					local v14_ = {}
					v10_[v12_] = v14_
					table.insert(v14_, v13_)
					for _ = 2, GuiSoundPlayer.NUM_SAMPLES_PER_SOUND do
						local v15_ = self.soundManager
						table.insert(v14_, v15_:cloneSample2D(v13_))
					end
				end
			end
		end
		delete(v11_)
	end
	return v10_
end

-- Local values: sampleList, sample, i
function GuiSoundPlayer:playSample(sampleName)
	if sampleName == GuiSoundPlayer.SOUND_SAMPLES.NONE then
		return
	end
	local v18_ = self.soundSamples[sampleName]
	if v18_ == nil then
		Logging.devWarning("Tried playing GUI sample \'%s\' which has not been loaded.", sampleName)
	else
		if v18_.lastTime ~= nil and g_time - v18_.lastTime < GuiSoundPlayer.SAMPLE_REPLAY_TIMEOUT then
			return
		end
		local v19_ = nil
		for v20_ = 1, #v18_ do
			if not self.soundManager:getIsSamplePlaying(v18_[v20_]) then
				v19_ = v18_[v20_]
				break
			end
		end
		if v19_ ~= nil then
			self.soundManager:playSample(v19_)
			v18_.lastTime = g_time
			return
		end
	end
end
