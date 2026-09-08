AudioGroup = {}
AudioGroup.groups = {}

function AudioGroup.getAudioGroupIndexByName(name)
	if name == nil then
		return nil
	end
	local v2_ = string.upper(name)
	return AudioGroup[v2_]
end

-- Local values: name, id
function AudioGroup.getAudioGroupNameByIndex(index)
	if index ~= nil then
		for v4_, v5_ in pairs(AudioGroup) do
			if index == v5_ then
				return v4_
			end
		end
	end
	return nil
end

-- Local values: _, index
function AudioGroup.getIsValidAudioGroup(audioGroupIndex)
	for _, v7_ in pairs(AudioGroup) do
		if v7_ == audioGroupIndex then
			return true
		end
	end
	return false
end

-- Local values: found, k, v
function AudioGroup.addGroup(name, id)
	local v10_ = string.upper(name)
	if AudioGroup[v10_] ~= nil then
		Logging.error("AudioGroup \'%s\' already defined!", v10_)
		return
	end
	local v11_ = false
	for _, v12_ in pairs(AudioGroup) do
		if v12_ == id then
			v11_ = true
			break
		end
	end
	if v11_ then
		Logging.error("AudioGroup id \'%d\' already defined", id)
	else
		AudioGroup[v10_] = id
		local v13_ = AudioGroup.groups
		local v14_ = AudioGroup[v10_]
		table.insert(v13_, v14_)
	end
end
function AudioGroup.getNextId()
	local v15_ = -1
	for _, v16_ in pairs(AudioGroup.groups) do
		local v17_ = v16_ + 1
		v15_ = math.max(v17_, v15_)
	end
	if v15_ == -1 or v15_ > 255 then
		return nil
	else
		return v15_
	end
end
function AudioGroup.loadGroups()
	local v18_ = loadXMLFile("AudioGroups", "shared/audioGroups.xml")
	if v18_ == 0 then
		Logging.error("Failed to load audio groups!")
		return
	end
	local v19_ = 0
	while true do
		local v20_ = string.format("audioGroups.audioGroup(%d)", v19_)
		if not hasXMLProperty(v18_, v20_) then
			delete(v18_)
			return
		end
		local v21_ = getXMLInt(v18_, v20_ .. "#id")
		local v22_ = getXMLString(v18_, v20_ .. "#name")
		if v21_ == nil then
			Logging.xmlError(v18_, "Missing id for audio group \'%s\'!", v20_)
		elseif v22_ == nil then
			Logging.xmlError(v18_, "Missing name for audio group \'%s\'!", v20_)
		else
			local v23_ = string.upper(v22_)
			if AudioGroup[v23_] == nil then
				local v24_ = false
				for _, v25_ in pairs(AudioGroup) do
					if v25_ == v21_ then
						v24_ = true
						break
					end
				end
				if v24_ then
					Logging.xmlError(v18_, "AudioGroup id \'%d\' already defined in \'%s\'!", v21_, v20_)
				else
					AudioGroup[v23_] = v21_
					local v26_ = AudioGroup.groups
					local v27_ = AudioGroup[v23_]
					table.insert(v26_, v27_)
				end
			else
				Logging.xmlError(v18_, "AudioGroup \'%s\' already defined in \'%s\'!", v23_, v20_)
			end
		end
		v19_ = v19_ + 1
	end
end
