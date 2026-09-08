
-- Local values: all, names, allOrdered, allOrderedByName, k, v, numBits, maxValue, i
function Enum(enum)
	local v_u_2_ = {}
	local v_u_3_ = {}
	local v_u_4_ = {}
	local v_u_5_ = {}
	for v6_, v7_ in pairs(enum) do
		if v7_ == 0 then
			Logging.error("Try to create an enum with item value 0. Enums have to be 1-based")
			printCallstack()
		end
		v_u_2_[v6_] = v7_
		v_u_3_[v7_] = v6_
		table.insert(v_u_4_, v7_)
		table.insert(v_u_5_, v6_)
	end
	table.sort(v_u_4_)
	table.sort(v_u_5_)
	
-- Upvalues: enum
function enum.getByName(name)
		-- upvalues: (copy) enum
		if name == nil then
			return nil
		else
			local v9_ = string.upper(name)
			if ClassUtil.getIsValidIndexName(v9_) then
				return enum[v9_]
			else
				return nil
			end
		end
	end
	
-- Upvalues: names
function enum.getName(id)
		-- upvalues: (copy) v_u_3_
		return v_u_3_[id]
	end
	function enum.getAll()
		-- upvalues: (copy) v_u_2_
		return v_u_2_
	end
	function enum.getAllOrdered()
		-- upvalues: (copy) v_u_4_
		return v_u_4_
	end
	function enum.getAllOrderedByName()
		-- upvalues: (copy) v_u_5_
		return v_u_5_
	end
	function enum.getAllNames()
		-- upvalues: (copy) v_u_3_
		return table.concat(v_u_3_, ", ")
	end
	local v11_ = unpack
	local v12_ = math.max(v11_(v_u_4_)) - 1
	local v_u_13_ = 1
	for _ = 1, 31 do
		if v12_ <= 2 ^ v_u_13_ - 1 then
			break
		end
		v_u_13_ = v_u_13_ + 1
	end
	function enum.getNumBits()
		-- upvalues: (ref) v_u_13_
		return v_u_13_
	end
	
-- Upvalues: numBits
-- Local values: value
function enum.writeStream(streamId, id)
		-- upvalues: (ref) v_u_13_
		local v16_ = id - 1
		streamWriteUIntN(streamId, v16_, v_u_13_)
	end
	
-- Upvalues: numBits
-- Local values: value
function enum.readStream(streamId)
		-- upvalues: (ref) v_u_13_
		return streamReadUIntN(streamId, v_u_13_) + 1
	end
	
-- Upvalues: enum
-- Local values: wrapped, name
function enum.loadFromXMLFile(xmlFile, key)
		-- upvalues: (copy) enum
		local v20_
		if type(xmlFile) == "number" then
			xmlFile = XMLFile.wrap(xmlFile)
			v20_ = true
		else
			v20_ = false
		end
		local v21_ = xmlFile:getString(key)
		if v20_ then
			xmlFile:delete()
		end
		return enum.getByName(v21_)
	end
	
-- Upvalues: enum, allOrdered, names
-- Local values: valueName, _, v, wrapped
function enum.saveToXMLFile(xmlFile, key, id)
		-- upvalues: (copy) enum, (copy) v_u_4_, (copy) v_u_3_
		local v25_ = enum.getName(id)
		if v25_ == nil then
			Logging.warning("Enum.saveToXMLFile(): Unable to get name for value %q, enum:", id)
			for _, v26_ in ipairs(v_u_4_) do
				printWarning("    " .. v_u_3_[v26_] .. ":" .. v26_)
			end
			printCallstack()
		else
			local v27_
			if type(xmlFile) == "number" then
				xmlFile = XMLFile.wrap(xmlFile)
				v27_ = true
			else
				v27_ = false
			end
			xmlFile:setString(key, v25_)
			if v27_ then
				xmlFile:delete()
			end
		end
	end
	
-- Upvalues: allOrderedByName
-- Local values: values
function enum.registerXMLPath(schema, path, description, defaultValue, isRequired)
		-- upvalues: (copy) v_u_5_
		local v33_ = v_u_5_
		schema:register(XMLValueType.STRING, path, description, defaultValue, isRequired, v33_)
	end
end
