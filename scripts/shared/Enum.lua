function Enum(enum)
	local all = {}
	local names = {}
	local allOrdered = {}
	local allOrderedByName = {}
	for k, v in pairs(enum) do
		if v == 0 then
			Logging.error("Try to create an enum with item value 0. Enums have to be 1-based")
			printCallstack()
		end
		all[k] = v
		names[v] = k
		table.insert(allOrdered, v)
		table.insert(allOrderedByName, k)
	end
	table.sort(allOrdered)
	table.sort(allOrderedByName)
	function enum.getByName(name)
		if name == nil then
			return nil
		end
		name = string.upper(name)
		if ClassUtil.getIsValidIndexName(name) then
			return enum[name]
		else
			return nil
		end
	end
	function enum.getName(id)
		return names[id]
	end
	function enum.getAll()
		return all
	end
	function enum.getAllOrdered()
		return allOrdered
	end
	function enum.getAllOrderedByName()
		return allOrderedByName
	end
	function enum.getAllNames()
		return table.concat(names, ", ")
	end
	local numBits = 1
	local maxValue = math.max(unpack(allOrdered)) - 1
	for i = 1, 31 do
		if maxValue <= 2 ^ numBits - 1 then
			break
		end
		numBits = numBits + 1
	end
	function enum.getNumBits()
		return numBits
	end
	function enum.writeStream(streamId, id)
		local value = id - 1
		streamWriteUIntN(streamId, value, numBits)
	end
	function enum.readStream(streamId)
		local value = streamReadUIntN(streamId, numBits)
		return value + 1
	end
	function enum.loadFromXMLFile(xmlFile, key)
		local wrapped = false
		if type(xmlFile) == "number" then
			xmlFile = XMLFile.wrap(xmlFile)
			wrapped = true
		end
		local name = xmlFile:getString(key)
		if wrapped then
			xmlFile:delete()
		end
		return enum.getByName(name)
	end
	function enum.saveToXMLFile(xmlFile, key, id)
		local valueName = enum.getName(id)
		if valueName == nil then
			Logging.warning("Enum.saveToXMLFile(): Unable to get name for value %q, enum:", id)
			for _, v in ipairs(allOrdered) do
				printWarning("    " .. names[v] .. ":" .. v)
			end
			printCallstack()
		else
			local wrapped = false
			if type(xmlFile) == "number" then
				xmlFile = XMLFile.wrap(xmlFile)
				wrapped = true
			end
			xmlFile:setString(key, valueName)
			if wrapped then
				xmlFile:delete()
			end
		end
	end
	function enum.registerXMLPath(schema, path, description, defaultValue, isRequired)
		local values = allOrderedByName
		schema:register(XMLValueType.STRING, path, description, defaultValue, isRequired, values)
	end
end
