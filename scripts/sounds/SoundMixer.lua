-- Local values: SoundMixer_mt
SoundMixer = {}
local SoundMixer_mt = Class(SoundMixer)

-- Upvalues: SoundMixer_mt
-- Local values: self, _, groupIndex
function SoundMixer.new(customMt)
	-- upvalues: (copy) SoundMixer_mt
	local v3_ = customMt or SoundMixer_mt
	local v4_ = setmetatable({}, v3_)
	g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, v4_.onGameStateChanged, v4_)
	v4_.masterVolume = 1
	v4_.gameStates = {}
	v4_.volumes = {}
	v4_.volumeFactors = {}
	v4_.volumeChangedListeners = {}
	for _, v5_ in pairs(AudioGroup.groups) do
		v4_.volumeFactors[v5_] = 1
		v4_.volumeChangedListeners[v5_] = {}
	end
	addConsoleCommand("gsSoundMixerDebug", "Toggle sound mixer debug mode", "consoleCommandToggleDebug", v4_)
	return v4_
end

-- Local values: _, groupIndex, xmlFile, i, gameStateKey, gameStateName, gameStateIndex, gameState, j, audioGroupKey, name, volume, fadeInDuration, fadeOutDuration, audioGroupIndex, currentGameState, gameStateAudioGroups, _, groupIndex, data, volume
function SoundMixer:loadFromXML(xmlFilepath)
	for _, v8_ in pairs(AudioGroup.groups) do
		self.volumeFactors[v8_] = self.volumeFactors[v8_] or 1
		self.volumeChangedListeners[v8_] = self.volumeChangedListeners[v8_] or {}
	end
	local v9_ = loadXMLFile("soundMixerXML", xmlFilepath)
	if v9_ ~= nil and v9_ ~= 0 then
		local v10_ = 0
		while true do
			local v11_ = string.format("soundMixer.gameState(%d)", v10_)
			if not hasXMLProperty(v9_, v11_) then
				break
			end
			local v12_ = getXMLString(v9_, v11_ .. "#name")
			local v13_ = g_gameStateManager:getGameStateIndexByName(v12_)
			if v13_ == nil then
				Logging.xmlWarning(v9_, "Game-State \'%s\' is not defined for state \'%s\'!", v12_, v11_)
			else
				local v14_ = 0
				local v15_ = {}
				while true do
					local v16_ = string.format("%s.audioGroup(%d)", v11_, v14_)
					if not hasXMLProperty(v9_, v16_) then
						break
					end
					local v17_ = getXMLString(v9_, v16_ .. "#name")
					local v18_ = getXMLFloat(v9_, v16_ .. "#volume") or 1
					local v19_ = (getXMLFloat(v9_, v16_ .. "#fadeOutDuration") or 0.5) * 1000
					local v20_ = (getXMLFloat(v9_, v16_ .. "#fadeOutDuration") or 0.5) * 1000
					local v21_ = AudioGroup.getAudioGroupIndexByName(v17_)
					if v21_ == nil then
						Logging.xmlWarning(v9_, "Audio-Group \'%s\' in game state \'%s\' (%s) is not defined!", v17_, v12_, v11_)
					else
						v15_[v21_] = {
							["volume"] = v18_,
							["fadeInDuration"] = v19_,
							["fadeOutDuration"] = v20_
						}
					end
					v14_ = v14_ + 1
				end
				self.gameStates[v13_] = v15_
			end
			v10_ = v10_ + 1
		end
		delete(v9_)
	end
	local v22_ = g_gameStateManager:getGameState()
	local v23_ = self.gameStates[v22_] or self.gameStates[GameState.LOADING]
	for _, v24_ in ipairs(AudioGroup.groups) do
		if v23_ then
			local _ = v23_[v24_]
		end
		self.volumes[v24_] = 0
		setAudioGroupVolume(v24_, 0)
	end
end

function SoundMixer:delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsSoundMixerDebug")
end

-- Local values: gameStateIndex, gameState, isDone, audioGroupIndex, data, currentVolume, target, dir, func, fadeDuration, changePerFrame, _, listener
function SoundMixer:update(dt)
	if self.isDirty then
		local v28_ = g_gameStateManager:getGameState()
		local v29_ = self.gameStates[v28_]
		if v29_ ~= nil then
			local v30_ = true
			for v31_, v32_ in pairs(v29_) do
				local v33_ = self.volumes[v31_]
				local v34_ = v32_.volume * self.volumeFactors[v31_]
				if v33_ ~= v34_ then
					v30_ = false
					local v35_ = math.min
					local v36_ = v32_.fadeInDuration
					local v37_
					if v34_ < v33_ then
						v35_ = math.max
						v36_ = v32_.fadeOutDuration
						v37_ = -1
					else
						v37_ = 1
					end
					local v38_ = v35_(v33_ + v37_ * (v36_ <= 0 and 1 or dt / v36_), v34_)
					setAudioGroupVolume(v31_, v38_)
					self.volumes[v31_] = v38_
					for _, v39_ in ipairs(self.volumeChangedListeners[v31_]) do
						v39_.func(v39_.target, v31_, v38_)
					end
				end
			end
			if v30_ then
				self.isDirty = false
			end
		end
	end
end

function SoundMixer:immediateUpdate()
	self:update(99999)
end

-- Local values: gameStateIndex, gameStateName, stateName, stateValue, lineIndex, gameState, audioGroupIndex, audioGroupData, currentVolume, targetVolume
function SoundMixer:drawDebug()
	local v42_ = g_gameStateManager:getGameState()
	local v43_ = "None"
	for v44_, v45_ in pairs(GameState) do
		if v45_ == v42_ then
			v43_ = v44_
			break
		end
	end
	renderText(0.8, 0.7, 0.015, string.format("current GameState: %s (%d)", v43_, v42_ or -1))
	local v46_ = 1
	setTextAlignment(RenderText.ALIGN_RIGHT)
	renderText(0.83, 0.7 - v46_ * 0.015, 0.015, "AudioGroup")
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(0.85, 0.7 - v46_ * 0.015, 0.015, "curVol")
	renderText(0.9, 0.7 - v46_ * 0.015, 0.015, "targetVol")
	renderText(0.95, 0.7 - v46_ * 0.015, 0.015, "volFactor")
	local v47_ = v46_ + 1
	local v48_ = self.gameStates[v42_]
	for v49_, v50_ in pairs(v48_) do
		local v51_ = self.volumes[v49_]
		local v52_ = v50_.volume * self.volumeFactors[v49_]
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.83, 0.7 - v47_ * 0.015, 0.015, string.format("%s (%d)", AudioGroup.getAudioGroupNameByIndex(v49_), v49_))
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.85, 0.7 - v47_ * 0.015, 0.015, string.format("%.2f", v51_))
		renderText(0.9, 0.7 - v47_ * 0.015, 0.015, string.format("%.2f", v52_))
		renderText(0.95, 0.7 - v47_ * 0.015, 0.015, string.format("%.2f", self.volumeFactors[v49_]))
		v47_ = v47_ + 1
	end
end

function SoundMixer:setAudioGroupVolumeFactor(audioGroupIndex, factor)
	if audioGroupIndex ~= nil and self.volumeFactors[audioGroupIndex] ~= nil then
		self.volumeFactors[audioGroupIndex] = factor
		self.isDirty = true
	end
end

function SoundMixer:getAudioGroupVolume(audioGroupIndex)
	return self.volumes[audioGroupIndex]
end

function SoundMixer:setMasterVolume(masterVolume)
	self.masterVolume = masterVolume
	setMasterVolume(masterVolume)
end

-- Local values: gameState
function SoundMixer:onGameStateChanged(gameStateId, oldGameState)
	if self.gameStates[gameStateId] ~= nil then
		self.isDirty = true
	end
end

function SoundMixer:addVolumeChangedListener(audioGroupIndex, func, target)
	if self.volumeChangedListeners[audioGroupIndex] == nil then
		self.volumeChangedListeners[audioGroupIndex] = {}
	end
	table.addElement(self.volumeChangedListeners[audioGroupIndex], {
		["func"] = func,
		["target"] = target
	})
end

function SoundMixer:consoleCommandToggleDebug()
	self.debugEnabled = not self.debugEnabled
	if g_debugManager ~= nil then
		if self.debugEnabled then
			g_debugManager:addDrawable(self)
		else
			g_debugManager:removeDrawable(self)
		end
	end
	return string.format("SoundMixer debugEnabled = %s", self.debugEnabled)
end
