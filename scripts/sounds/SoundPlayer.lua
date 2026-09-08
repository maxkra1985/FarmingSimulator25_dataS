-- Local values: SoundPlayer_mt
SoundPlayer = {}
local SoundPlayer_mt = Class(SoundPlayer)

-- Upvalues: SoundPlayer_mt
-- Local values: self
function SoundPlayer.new(appBasePath, webDataXMLFile, localDataXMLFilename, localFolder, userLocalFolder, languageShort, soundGroup)
	-- upvalues: (copy) SoundPlayer_mt
	local v9_ = SoundPlayer_mt
	local v10_ = setmetatable({}, v9_)
	v10_.soundPlayerId = createSoundPlayer("SoundPlayer", appBasePath, webDataXMLFile, localDataXMLFilename, localFolder, userLocalFolder, languageShort, soundGroup)
	if v10_.soundPlayerId == nil or v10_.soundPlayerId == 0 then
		print("Could not create sound player")
		return nil
	end
	v10_.channelNameReplacements = {}
	v10_.channelIcons = {}
	v10_:loadReplacements({ localFolder, userLocalFolder })
	v10_.currentChannel = 0
	v10_.currentItem = 0
	v10_.initialized = false
	v10_.currentChannelName = ""
	v10_.currentItemName = ""
	v10_.updateTimer = 0
	v10_.switchInNextFrame = false
	v10_.channelItemMapping = {}
	v10_.eventListener = {}
	v10_.streamingAccessOwner = nil
	return v10_
end

function SoundPlayer:delete()
	self.channelNameReplacements = {}
	self.channelIcons = {}
	if self.soundPlayerId ~= nil then
		delete(self.soundPlayerId)
	end
end

-- Local values: channelName, itemName, isOnlineStream
function SoundPlayer:update(dt)
	if isSoundPlayerLoaded(self.soundPlayerId) and self.isPlaying then
		if isSoundPlayerPlaying(self.soundPlayerId) then
			self.updateTimer = self.updateTimer + dt
			if self.updateTimer > 500 then
				local v14_ = self:getChannelName()
				local v15_ = self:getItemName()
				if v14_ ~= nil and (v15_ ~= nil and (v14_ ~= self.currentChannelName or v15_ ~= self.currentItemName)) then
					self:onChange(v14_, v15_, (getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel)))
					self.currentChannelName = v14_
					self.currentItemName = v15_
				end
				self.updateTimer = 0
			end
			self.switchInNextFrame = false
			return
		end
		if not getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel) then
			if self.switchInNextFrame then
				self:nextItem()
				self.switchInNextFrame = false
				return
			end
			self.switchInNextFrame = true
		end
	end
end

-- Local values: _, folder, filename, xmlFile
function SoundPlayer:loadReplacements(folders)
	for _, v18_ in ipairs(folders) do
		local v19_ = v18_ .. "/music.xml"
		if fileExists(v19_) then
			local v_u_20_ = XMLFile.load("music", v19_)
			v_u_20_:iterate("music.radio.channels.channel", function(_, p21_)
				-- upvalues: (copy) v_u_20_, (copy) self
				local v22_ = v_u_20_:getString(p21_ .. "#name")
				local v23_ = v_u_20_:getString(p21_ .. "#replacement")
				local v24_ = Utils.getFilename(v_u_20_:getString(p21_ .. "#icon"))
				if v22_ ~= nil and v23_ ~= nil then
					self.channelNameReplacements[string.lower(v22_)] = v23_
					if v24_ ~= nil then
						self.channelIcons[string.lower(v22_)] = v24_
					end
				end
			end)
			v_u_20_:delete()
		end
	end
end

-- Local values: name, _, eventListener
function SoundPlayer:onChange(channelName, itemName, isOnlineStream)
	local v29_ = string.lower(channelName)
	local v30_ = self.channelNameReplacements[v29_] or channelName
	for _, v31_ in ipairs(self.eventListener) do
		v31_:onSoundPlayerChange(v30_, itemName, isOnlineStream, self.channelIcons[v29_])
	end
end

function SoundPlayer:addEventListener(listener)
	if listener ~= nil then
		table.addElement(self.eventListener, listener)
	end
end

function SoundPlayer:removeEventListener(listener)
	if listener ~= nil then
		table.removeElement(self.eventListener, listener)
	end
end

function SoundPlayer:setStreamingAccessOwner(owner)
	self.streamingAccessOwner = owner
end

-- Local values: channelName, itemName, isOnlineStream
function SoundPlayer:updateMetaData()
	local v39_ = getSoundPlayerChannelName(self.soundPlayerId, self.currentChannel)
	local v40_ = getSoundPlayerItemName(self.soundPlayerId)
	self.currentChannelName = v39_
	self.currentItemName = v40_
	self:onChange(v39_, v40_, (getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel)))
end

-- Local values: lastChannel
function SoundPlayer:previousChannel()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		local v42_ = self.currentChannel
		self.currentChannel = self.currentChannel - 1
		if self.currentChannel < 0 then
			self.currentChannel = getNumSoundPlayerChannels(self.soundPlayerId) - 1
		end
		if v42_ ~= self.currentChannel then
			self:changeChannel(v42_)
			return true
		end
	end
	return false
end

-- Local values: lastChannel
function SoundPlayer:nextChannel()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		local v44_ = self.currentChannel
		self.currentChannel = self.currentChannel + 1
		if self.currentChannel >= getNumSoundPlayerChannels(self.soundPlayerId) then
			self.currentChannel = 0
		end
		if v44_ ~= self.currentChannel then
			self:changeChannel(v44_)
			return true
		end
	end
	return false
end

function SoundPlayer:startChannel()
	self.currentItem = Utils.getNoNil(self.channelItemMapping[self.currentChannel], 0)
	setSoundPlayerChannel(self.soundPlayerId, self.currentChannel)
	setSoundPlayerItem(self.soundPlayerId, self.currentItem)
	self:play()
	self:updateMetaData()
end

function SoundPlayer:changeChannel(lastChannel)
	if self.streamingAccessOwner == nil or not getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel) then
		self:startChannel()
	else
		if getIsSoundPlayerChannelStreamed(self.soundPlayerId, lastChannel) then
			self:pause()
		end
		self.streamingAccessOwner:onSoundPlayerStreamAccess()
	end
end

function SoundPlayer:setStreamAccessAllowed(yes)
	if not yes then
		while getIsSoundPlayerChannelStreamed(self.soundPlayerId, self.currentChannel) do
			self.currentChannel = self.currentChannel + 1
			if self.currentChannel >= getNumSoundPlayerChannels(self.soundPlayerId) then
				self.currentChannel = 0
			end
		end
	end
	self:startChannel()
end

-- Local values: lastItem
function SoundPlayer:nextItem()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		local v51_ = self.currentItem
		self.currentItem = self.currentItem + 1
		if self.currentItem >= getNumSoundPlayerItems(self.soundPlayerId) then
			self.currentItem = 0
		end
		if v51_ ~= self.currentItem or getNumSoundPlayerItems(self.soundPlayerId) == 1 then
			setSoundPlayerItem(self.soundPlayerId, self.currentItem)
			self.channelItemMapping[self.currentChannel] = self.currentItem
			self:play()
			self:updateMetaData()
			return true
		end
	end
	return false
end

-- Local values: lastItem
function SoundPlayer:previousItem()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		local v53_ = self.currentItem
		self.currentItem = self.currentItem - 1
		if self.currentItem < 0 then
			self.currentItem = getNumSoundPlayerItems(self.soundPlayerId) - 1
		end
		if v53_ ~= self.currentItem or getNumSoundPlayerItems(self.soundPlayerId) == 1 then
			setSoundPlayerItem(self.soundPlayerId, self.currentItem)
			self.channelItemMapping[self.currentChannel] = self.currentItem
			self:play()
			self:updateMetaData()
			return true
		end
	end
	return false
end

function SoundPlayer:play()
	if not isSoundPlayerLoaded(self.soundPlayerId) then
		return false
	end
	self:initializeSoundPlayer()
	playSoundPlayer(self.soundPlayerId)
	self:updateMetaData()
	self.isPlaying = true
	return true
end

function SoundPlayer:pause()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		self.isPlaying = false
		self.switchInNextFrame = false
		self.currentChannelName = ""
		self.currentItemName = ""
		if isSoundPlayerPlaying(self.soundPlayerId) then
			pauseSoundPlayer(self.soundPlayerId)
			return true
		end
	end
	return false
end

function SoundPlayer:getIsPlaying()
	return self.isPlaying
end

function SoundPlayer:getChannelName()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		return getSoundPlayerChannelName(self.soundPlayerId, self.currentChannel)
	else
		return nil
	end
end

function SoundPlayer:getItemName()
	if isSoundPlayerLoaded(self.soundPlayerId) then
		return getSoundPlayerItemName(self.soundPlayerId)
	else
		return nil
	end
end

-- Local values: i, numSoundPlayerItems
function SoundPlayer:initializeSoundPlayer()
	if not self.initialized and isSoundPlayerLoaded(self.soundPlayerId) then
		for v60_ = 0, 3 do
			setSoundPlayerChannel(self.soundPlayerId, v60_)
			local v61_ = getNumSoundPlayerItems(self.soundPlayerId) - 1
			if v61_ >= 0 then
				self.channelItemMapping[v60_] = math.random(0, v61_)
			else
				self.channelItemMapping[v60_] = 0
			end
		end
		self.currentChannel = math.random(0, 3)
		setSoundPlayerChannel(self.soundPlayerId, self.currentChannel)
		self.currentItem = self.channelItemMapping[self.currentChannel]
		setSoundPlayerItem(self.soundPlayerId, self.currentItem)
		self.initialized = true
	end
end
