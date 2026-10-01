AudioGroup = {}
AudioGroup.groups = {}
function AudioGroup.getAudioGroupIndexByName(name)
	if name ~= nil then
		name = string.upper(name)
		return AudioGroup[name]
	else
		return nil
	end
end
function AudioGroup.getAudioGroupNameByIndex(index)
	if index ~= nil then
		for name, id in pairs(AudioGroup) do
			if index == id then
				return name
			end
		end
	end
	return nil
end
function AudioGroup.getIsValidAudioGroup(audioGroupIndex)
	for _, index in pairs(AudioGroup) do
		if index == audioGroupIndex then
			return true
		end
	end
	return false
end
function AudioGroup.addGroup(name, id)
	name = string.upper(name)
	if AudioGroup[name] == nil then
		local found = false
		for k, v in pairs(AudioGroup) do
			if v == id then
				found = true
				break
			end
		end
		if not found then
			AudioGroup[name] = id
			table.insert(AudioGroup.groups, AudioGroup[name])
			return
		else
			Logging.error("AudioGroup id '%d' already defined", id)
			return
		end
	end
	Logging.error("AudioGroup '%s' already defined!", name)
end
function AudioGroup.getNextId()
	local nextFreeId = -1
	for _, index in pairs(AudioGroup.groups) do
		nextFreeId = math.max(index + 1, nextFreeId)
	end
	if nextFreeId == -1 or 255 < nextFreeId then
		return nil
	end
	return nextFreeId
end
function AudioGroup.loadGroups()
	local xmlFile = loadXMLFile("AudioGroups", "shared/audioGroups.xml")
	if xmlFile == 0 then
		Logging.error("Failed to load audio groups!")
	else
		local i = 0
		while true do
			local key = string.format("audioGroups.audioGroup(%d)", i)
			if not hasXMLProperty(xmlFile, key) then
				break
			end
			local id = getXMLInt(xmlFile, key .. "#id")
			local name = getXMLString(xmlFile, key .. "#name")
			if id == nil then
				Logging.xmlError(xmlFile, "Missing id for audio group '%s'!", key)
			elseif name == nil then
				Logging.xmlError(xmlFile, "Missing name for audio group '%s'!", key)
			else
				name = string.upper(name)
				if AudioGroup[name] == nil then
					local found = false
					for k, v in pairs(AudioGroup) do
						if v == id then
							found = true
							break
						end
					end
					if not found then
						AudioGroup[name] = id
						table.insert(AudioGroup.groups, AudioGroup[name])
					else
						Logging.xmlError(xmlFile, "AudioGroup id '%d' already defined in '%s'!", id, key)
					end
				else
					Logging.xmlError(xmlFile, "AudioGroup '%s' already defined in '%s'!", name, key)
				end
			end
			i = i + 1
		end
		delete(xmlFile)
	end
end
